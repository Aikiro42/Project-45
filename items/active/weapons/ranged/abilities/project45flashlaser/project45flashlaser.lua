require "/scripts/vec2.lua"

Project45FlashLaser = WeaponAbility:new()

local OFF, FLASH, LASER, FLASHLASER = 1, 2, 3, 4

function Project45FlashLaser:init()
  self:reset()
  self.flashLaserStates = {"off", "flash", "laser", "flashlaser"}
end

function Project45FlashLaser:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  -- render laser
  if (storage.state == FLASHLASER or storage.state == LASER) and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    local scanOrig = self:firePosition()
    local range = world.magnitude(scanOrig, activeItem.ownerAimPosition())
    local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(), self.laserRange))
    scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest
    activeItem.setScriptedAnimationParameter("laserOrigin", scanOrig)
    activeItem.setScriptedAnimationParameter("laserDestination", scanDest)
  end

  if self.fireMode == "alt" and self.lastFireMode ~= "alt" then
    storage.state = (storage.state % 4) + 1
    animator.setAnimationState("project45flashlaser", self.flashLaserStates[storage.state])
    if storage.state == FLASH or storage.state == FLASHLASER then
      animator.setLightActive("flashlight", true)
      animator.setLightActive("flashlightSpread", true)
      animator.playSound("flashlight")
    else
      animator.setLightActive("flashlight", false)
      animator.setLightActive("flashlightSpread", false)
    end
    

    if not (storage.state == FLASHLASER or storage.state == LASER) then
      activeItem.setScriptedAnimationParameter("laserOrigin", nil)
      activeItem.setScriptedAnimationParameter("laserDestination", nil)
      activeItem.setScriptedAnimationParameter("altLaserColor", nil)
      activeItem.setScriptedAnimationParameter("altLaserWidth", nil)
    else
      activeItem.setScriptedAnimationParameter("altLaserColor", self.laserColor)
      activeItem.setScriptedAnimationParameter("altLaserWidth", self.laserWidth)
      animator.playSound("laser")
    end

  end
  self.lastFireMode = fireMode
end

function Project45FlashLaser:reset()
  storage.state = storage.state or OFF
  if storage.state == FLASH or storage.state == FLASHLASER then
    animator.setLightActive("flashlight", true)
    animator.setLightActive("flashlightSpread", true)
    animator.playSound("flashlight")
  else
    animator.setLightActive("flashlight", false)
    animator.setLightActive("flashlightSpread", false)
  end
end

function Project45FlashLaser:uninit()
  self:reset()
end

function Project45FlashLaser:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(self.weapon.muzzleOffset, self.weapon.relativeWeaponRotation)))
end

function Project45FlashLaser:aimVector()
  local firePos = self:firePosition()
  local basePos =  vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate({0, self.weapon.muzzleOffset[2]}, self.weapon.relativeWeaponRotation)))
  world.debugPoint(firePos, "cyan")
  world.debugPoint(basePos, "cyan")
  local aimVector = vec2.norm(world.distance(firePos, basePos))
  aimVector = vec2.rotate(aimVector, sb.nrand((inaccuracy or 0), 0))
  return aimVector
end