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

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  self.movementSpeedFactor = config.getParameter("movementSpeedFactor", 1.15)
  self.jumpHeightFactor = config.getParameter("jumpHeightFactor", 1.15)

  --[[
  damageL = damageListener("inflictedDamage", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId == activeItem.ownerEntityId() then
        sb.logInfo("[PROJECT 45] " .. sb.printJson(notification))
      end
    end
  end)
  --]]


  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
  -- damageL:update()
  activeItem.setScriptedAnimationParameter("gunHand", activeItem.hand())
  activeItem.setScriptedAnimationParameter("aimPosition", activeItem.ownerAimPosition())
  activeItem.setScriptedAnimationParameter("playerPos", mcontroller.position())
  
  if not status.resourceLocked("energy") then status.setResource("energyRegenBlock", 1.0) end

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
