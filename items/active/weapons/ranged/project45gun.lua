require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  self.movementSpeedFactor = config.getParameter("movementSpeedFactor", 1.15)
  self.jumpHeightFactor = config.getParameter("jumpHeightFactor", 1.15)

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
  
  activeItem.setScriptedAnimationParameter("gunHand", activeItem.hand())
  activeItem.setScriptedAnimationParameter("aimPosition", activeItem.ownerAimPosition())

  if shiftHeld then
    mcontroller.controlModifiers({
      speedModifier = 1,
      airJumpModifier = self.jumpHeightFactor
    })
  else
    mcontroller.controlModifiers({
      speedModifier = self.movementSpeedFactor,
      airJumpModifier = self.jumpHeightFactor
    })
  end

end

function uninit()
  self.weapon:uninit()
end
