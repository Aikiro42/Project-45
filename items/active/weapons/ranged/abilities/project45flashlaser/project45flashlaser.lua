require "/scripts/vec2.lua"

Project45FlashLaser = WeaponAbility:new()

local STATES = 4
local OFF, FLASHLIGHT, LASER, BOTH = 0, 1, 2, 3

function Project45FlashLaser:init()
  activeItem.setScriptedAnimationParameter("laserColor", self.laserColor)
  self:reset()
end

function Project45FlashLaser:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  -- render laser
  if (self.state == BOTH or self.state == LASER) and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    local scanOrig = self:firePosition()
    local range = world.magnitude(scanOrig, activeItem.ownerAimPosition())
    local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(), self.laserRange))
    scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest
    activeItem.setScriptedAnimationParameter("laserOrigin", scanOrig)
    activeItem.setScriptedAnimationParameter("laserDestination", scanDest)
  end

  if self.fireMode == "alt" and self.lastFireMode ~= "alt" then
    self.state = (self.state + 1) % STATES
    if self.state == FLASHLIGHT or self.state == BOTH then
      animator.setLightActive("flashlight", true)
      animator.setLightActive("flashlightSpread", true)
      animator.playSound("flashlight")
    else
      animator.setLightActive("flashlight", false)
      animator.setLightActive("flashlightSpread", false)
    end
    

    if not (self.state == BOTH or self.state == LASER) then
      activeItem.setScriptedAnimationParameter("laserOrigin", nil)
      activeItem.setScriptedAnimationParameter("laserDestination", nil)
    else
      animator.playSound("laser")
    end

  end
  self.lastFireMode = fireMode
end

function Project45FlashLaser:reset()
  animator.setLightActive("flashlight", false)
  animator.setLightActive("flashlightSpread", false)
  self.state = OFF
end

function Project45FlashLaser:uninit()
  self:reset()
end

function Project45FlashLaser:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(self.weapon.muzzleOffset, self.weapon.relativeWeaponRotation)))
end

function Project45FlashLaser:aimVector()
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand((0), 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  aimVector = vec2.rotate(aimVector, (self.weapon.relativeArmRotation + self.weapon.relativeWeaponRotation) * mcontroller.facingDirection())
  return aimVector
end