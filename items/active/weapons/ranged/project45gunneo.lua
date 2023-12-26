require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  local generalConfig = root.assetJson("/configs/project45/project45_generalconfig.config")
  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("beamEnd", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)
  self.weapon:addTransformationGroup("altmuzzle", config.getParameter("altMuzzleOffset", self.weapon.muzzleOffset), 0)
  self.weapon:addTransformationGroup("ejectionPort", config.getParameter("ejectionPortOffset", {0,0}), 0)
  self.weapon:addTransformationGroup("magazine", config.getParameter("magazineOffset", {0,0}), 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  activeItem.setScriptedAnimationParameter("hand", activeItem.hand())
  activeItem.setScriptedAnimationParameter("renderBarsAtCursor", generalConfig.renderBarsAtCursor)
  activeItem.setScriptedAnimationParameter("project45GunFireMessages", config.getParameter("project45GunFireMessages", {}))
  activeItem.setInstanceValue("project45GunFireMessages", {})
  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
  self.weapon:uninit()
end
