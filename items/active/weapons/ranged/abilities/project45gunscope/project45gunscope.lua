require "/items/active/weapons/weapon.lua"
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

function Project45GunScope:drawLaser(a)
  if a == "alt" then
    activeItem.setScriptedAnimationParameter("laserOrigin", self:firePosition())
    activeItem.setScriptedAnimationParameter("laserDestination", activeItem.ownerAimPosition())
  else
    activeItem.setScriptedAnimationParameter("laserOrigin", nil)
    activeItem.setScriptedAnimationParameter("laserDestination", nil)
  end
end

function Project45GunScope:updateCamera(shiftHeld)
  if shiftHeld == "alt" then
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
      world.callScriptedEntity(storage.cameraProjectile, "updatePos", activeItem.ownerAimPosition(), mcontroller.position(), 100, self.deadzone)
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
  
function SynthetikMechanics:screenShake(amount, shakeTime, random)
end