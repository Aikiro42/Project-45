require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/shields/shield.lua"

function setStance(stance)
  self.stance = stance
  self.aimAngle = stance.aimAngle or self.aimAngle
  self.relativeShieldRotation = util.toRadians(stance.shieldRotation) or 0
  self.relativeArmRotation = util.toRadians(stance.armRotation) or 0
end

function updateAim()
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  
  if self.stance.allowRotate then
    self.aimAngle = aimAngle
  else
    self.aimAngle = self.stance.aimAngle or 0
  end
  activeItem.setArmAngle(self.aimAngle + self.relativeArmRotation)

  if self.stance.allowFlip then
    self.aimDirection = aimDirection
  end
  activeItem.setFacingDirection(self.aimDirection)

  animator.setGlobalTag("hand", isNearHand() and "near" or "far")
  activeItem.setOutsideOfHand(not self.active or isNearHand())
end

function shieldHealth()
  return self.baseShieldHealth * status.resourceMax("energy")
end
