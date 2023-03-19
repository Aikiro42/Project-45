require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

-- require "/scripts/status.lua"
-- local damageL

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)
  self.weapon:addTransformationGroup("ejectionPort", config.getParameter("ejectionPortOffset", {0,0}), 0)
  self.weapon:addTransformationGroup("magazine", config.getParameter("magazineOffset", {0,0}), 0)
  activeItem.setScriptedAnimationParameter("shortDescription", config.getParameter("shortdescription", "unknown"))

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
  -- damageL:update()
  activeItem.setScriptedAnimationParameter("gunHand", activeItem.hand())
  activeItem.setScriptedAnimationParameter("aimPosition", activeItem.ownerAimPosition())
  activeItem.setScriptedAnimationParameter("playerPos", mcontroller.position())

end

function uninit()
  self.weapon:uninit()
end
