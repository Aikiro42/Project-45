require "/items/active/weapons/weapon.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/ranged/abilities/synthetikmechanics/synthetikmechanics.lua"

Project45GunScope = WeaponAbility:new()

function Project45GunScope:init()
  storage.cameraProjectile = storage.cameraProjectile or nil
  self.lerpProgress = 0
  self.state = 0
end

function Project45GunScope:update(dt, fireMode, shiftHeld)

  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  local trigger = self.fireMode
  self:updateCamera(trigger)
  self:drawLaser(trigger)
    
end

function Project45GunScope:uninit()
  if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then
    world.callScriptedEntity(storage.cameraProjectile, "die")
  end
end

function Project45GunScope:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(self.weapon.muzzleOffset, self.weapon.relativeWeaponRotation)))
end

function Project45GunScope:drawLaser(trigger)
  if trigger == "alt" then
    activeItem.setScriptedAnimationParameter("laserOrigin", self:firePosition())
    if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then
      activeItem.setScriptedAnimationParameter("laserDestination", world.entityPosition(storage.cameraProjectile))
    end
  elseif trigger == "none" then
    activeItem.setScriptedAnimationParameter("laserOrigin", nil)
    activeItem.setScriptedAnimationParameter("laserDestination", nil)
  end
end

function Project45GunScope:updateCamera(shiftHeld)
  -- if altfire then
  if shiftHeld == "alt" then


    -- update state
    if self.state == 0 then
      -- play sound of looking into scope
      self.state = 1
    end
    self.lerpProgress = math.max(0, self.lerpProgress - self.dt)

    -- generate projectile if nonexistent
    storage.cameraProjectile = storage.cameraProjectile or world.spawnProjectile(
      "project45camera",
      mcontroller.position(),
      activeItem.ownerEntityId(),
      {0, 0},
      true,
      {power = 0}
    )

    -- update projectile position
    if world.entityExists(storage.cameraProjectile) then
      world.callScriptedEntity(storage.cameraProjectile, "updatePos", activeItem.ownerAimPosition(), mcontroller.position(), 100, self.deadzone, self.maxSpeed)
      activeItem.setCameraFocusEntity(storage.cameraProjectile)
    end
  elseif shiftHeld == "none" then
    
    if self.state == 1 then
      -- play sound of putting scope away
      self.state = 0
    end

    self.lerpProgress = math.min(1, self.lerpProgress + self.dt)
    if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then
      world.callScriptedEntity(storage.cameraProjectile, "lerpToSource", mcontroller.position(), self.lerpProgress)
      activeItem.setCameraFocusEntity(storage.cameraProjectile)
    else
      storage.cameraProjectile = nil
    end
  end
end

function SynthetikMechanics:aim()
  if self.reloadTimer < 0 then
    local stance = storage.targetStance
    
    if self.aimProgress == 1 then activeItem.setRecoil(true) end
    
    activeItem.setFrontArmFrame(stance.frontArmFrame)
    activeItem.setBackArmFrame(stance.backArmFrame)
    
    if config.getParameter("twoHanded", false) then activeItem.setTwoHandedGrip(stance.twoHanded or false) end
    

    -- force weapon to face crosshair
    if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then
      self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, world.entityPosition(storage.cameraProjectile))
    else
      self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
    end
    
    self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeWeaponRotation), stance.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeArmRotation), stance.armRotation))


  end
end


function SynthetikMechanics:hitscan(isLaser)

  local scoped = storage.cameraProjectile and world.entityExists(storage.cameraProjectile)

  local scanOrig = self:firePosition()

  local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(isLaser and 0 or self.inaccuracy), self.projectileParameters.range or 100))
  if scoped then
    scanDest = world.entityPosition(storage.cameraProjectile)
  end
  scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest
  

  -- hitreg
  local hitId = world.entityLineQuery(scanOrig, scanDest, {
    withoutEntityId = entity.id(),
    includedTypes = {"monster", "npc", "player"},
    order = "nearest"
  })

  local eid = {}
  local pen = 0
  if #hitId > 0 then
    for i, id in ipairs(hitId) do
      if world.entityCanDamage(entity.id(), id) then

        local aimAngle = vec2.angle(world.distance(scanDest, scanOrig))
        local entityAngle = vec2.angle(world.distance(world.entityPosition(id), scanOrig))
        local rotation = aimAngle - entityAngle
        if not scoped then
          scanDest = vec2.rotate(world.distance(world.entityPosition(id), scanOrig), rotation)
          scanDest = vec2.add(scanDest, scanOrig)
        end

        table.insert(eid, id)

        pen = pen + 1

        if not scoped and pen > (self.projectileParameters.punchThrough or 0) then break end
      end      
    end
  end
  
  world.debugLine(scanOrig, scanDest, {255,0,255})

  return {scanOrig, scanDest, eid}
end
  
function SynthetikMechanics:screenShake(amount, shakeTime, random)
  if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then
    world.callScriptedEntity(storage.cameraProjectile, "jerk")
    activeItem.setCameraFocusEntity(storage.cameraProjectile)
  else
    local source = mcontroller.position()
    local shake_dir = vec2.mul(self:aimVector(0), -1 * (amount or 0.1))
    if random then vec2.rotate(shake_dir, 3.14 * truerand()) end
    local cam = world.spawnProjectile(
      "invisibleprojectile",
      vec2.add(source, shake_dir),
      0,
      {0, 0},
      false,
      {
        power = 0,
        timeToLive = shakeTime or 0.01,
        damageType = "NoDamage"
      }
    )
    activeItem.setCameraFocusEntity(cam)
  end
end