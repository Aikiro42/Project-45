---@diagnostic disable: lowercase-global
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/project45neoweapon.lua"

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  
  local generalConfig = root.assetJson("/configs/project45/project45_general.config")
  
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

  local challengeScaling = -1

  local shiftAbility = getShiftAbility()
  if shiftAbility then
    if shiftAbility.magicNumber == "Throughout heaven and earth, I alone am the chosen one." then
      challengeScaling = (player and player.getProperty or status.statusProperty)("project45_challengeScaling", generalConfig.challengeScaling or 0)
    end
    self.weapon:addAbility(shiftAbility)
  end
    
  activeItem.setScriptedAnimationParameter("hand", activeItem.hand())

  local userSettings = {
    "renderBarsAtCursor",
    "useAmmoCounterImages"
    -- ,"accurateBars"
  }

  for _, setting in ipairs(userSettings) do
    activeItem.setScriptedAnimationParameter(
      setting,
      (player and player.getProperty or status.statusProperty)("project45_" .. setting,
      generalConfig[setting])
    )
  end

  local msg = config.getParameter("project45GunFireMessages", {nil})

  if challengeScaling > -1 and challengeScaling < 0.2 then
    if #msg > 0 then
      table.insert(msg, "Set Challenge Scaling to at least 20%")
    else
      msg = {"Set Challenge Scaling to at least 20%"}
    end
  end

  activeItem.setScriptedAnimationParameter("project45GunFireMessages", msg)
  activeItem.setInstanceValue("project45GunFireMessages", {})
  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)

  --[[
  if (storage.project45GunState.ammo > 0 and self.weapon.reloadTimer < 0)
  or not status.resourceLocked("energy") then
    status.setResource("energyRegenBlock", 1)
  end
  --]]
end

function uninit()
  self.weapon:uninit()
end
