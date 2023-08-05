require "/items/active/weapons/weapon.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/ranged/abilities/synthetikmechanics/synthetikmechanics.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/project45gunfire.lua"

Project45GunScope = WeaponAbility:new()

function Project45GunScope:init()
  storage.cameraProjectile = storage.cameraProjectile or nil
  self.lerpProgress = 0
  self.state = 0
end

function Project45GunScope:update(dt, fireMode, shiftHeld)

  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  local trigger = self.fireMode

  if storage.cameraProjectile then
    activeItem.setScriptedAnimationParameter("altLaserColor", self.laserColor)
    activeItem.setScriptedAnimationParameter("altLaserWidth", self.laserWidth)
  else
    activeItem.setScriptedAnimationParameter("altLaserColor", nil)
    activeItem.setScriptedAnimationParameter("altLaserWidth", nil)
  end
  
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

-- draws laser from gun to crosshair
function Project45GunScope:drawLaser(trigger)
  if not self.laser then return end
  if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then

    local scanOrig = self:firePosition()
    local range = world.magnitude(scanOrig, activeItem.ownerAimPosition())
    local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(0), math.min(self.range*2, range)))
    scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest

    activeItem.setScriptedAnimationParameter("laserOrigin", scanOrig)
    activeItem.setScriptedAnimationParameter("altLaserStart", scanOrig)
    activeItem.setScriptedAnimationParameter("laserDestination", scanDest)
    activeItem.setScriptedAnimationParameter("altLaserEnd", scanDest)

  else
    activeItem.setScriptedAnimationParameter("altLaserEnabled", false)
    activeItem.setScriptedAnimationParameter("altLaserStart", nil)
    activeItem.setScriptedAnimationParameter("altLaserEnd", nil)

  end
end

function Project45GunScope:updateCamera(shiftHeld)

  local source = mcontroller.position()

  -- if altfire then
  if shiftHeld == "alt" then

    -- update state
    if self.state == 0 then
      animator.playSound("aimFoley")
      if self.laser then animator.playSound("laser") end
      self.state = 1
    end
    self.lerpProgress = math.max(0, self.lerpProgress - self.dt)

    -- generate projectile if nonexistent
    storage.cameraProjectile = storage.cameraProjectile or world.spawnProjectile(
      "project45camera",
      source,
      activeItem.ownerEntityId(),
      {0, 0},
      true,
      {power = 0}
    )

    -- update projectile position
    if world.entityExists(storage.cameraProjectile) then
      --[[
      local scanOrig = self:firePosition()
      local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(0), self.range))
      scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest
      --]]
      world.callScriptedEntity(
        storage.cameraProjectile,
        "updatePos",
        activeItem.ownerAimPosition(),
        source,
        -- world.magnitude(mcontroller.position(), scanDest),
        self.range,
        self.deadzone, self.maxSpeed, self.maxSpeedDistance)

      activeItem.setCameraFocusEntity(storage.cameraProjectile)
    end

  -- if no button is pressed
  elseif shiftHeld == "none" then
    
    if self.state == 1 then
      -- turn off laser
      activeItem.setScriptedAnimationParameter("laserOrigin", nil)
      activeItem.setScriptedAnimationParameter("laserDestination", nil)
      self.state = 0
    end

    -- move crosshair back to player if camera projectile exists and is trackable
    self.lerpProgress = math.min(1, self.lerpProgress + self.dt)
    if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then
      world.callScriptedEntity(
        storage.cameraProjectile,
        "lerpToSource",
        mcontroller.position(), self.lerpProgress)
      activeItem.setCameraFocusEntity(storage.cameraProjectile)
    else
      -- case for when a nonexistent cameraProjectile is tracked
      -- important to nullify this variable to allow tracking camera projectiles
      storage.cameraProjectile = nil
    end
  end
end

function Project45GunScope:aimVector(inaccuracy)
  local firePos = self:firePosition()
  local basePos =  vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate({0, self.weapon.muzzleOffset[2]}, self.weapon.relativeWeaponRotation)))
  world.debugPoint(firePos, "cyan")
  world.debugPoint(basePos, "cyan")
  local aimVector = vec2.norm(world.distance(firePos, basePos))
  aimVector = vec2.rotate(aimVector, sb.nrand((inaccuracy or 0), 0))
  return aimVector
end

-- COMPATIBILITY FUNCTIONS

function SynthetikMechanics:screenShake(amount, shakeTime, random)
  if not self.doScreenShake then return end
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

function Project45GunFire:screenShake(amount, shakeTime, random)
  if self.usedByNPC or self.performanceMode then return end
  local amount = amount or self.currentScreenShake or 0.1
  if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then
    world.callScriptedEntity(storage.cameraProjectile, "jerk")
    activeItem.setCameraFocusEntity(storage.cameraProjectile)
  else
    local source = mcontroller.position()
    local shake_dir = vec2.mul(self:aimVector(0), -1 * (amount))
    if random then vec2.rotate(shake_dir, 3.14 * math.random()) end
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