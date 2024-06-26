require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/project45neoweapon.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45Armadillo = WeaponAbility:new()

function Project45Armadillo:init()
  self.shieldRadius = self.shieldRadius or 3
  self.shieldOffset = self.shieldOffset or {0, -0.5}
  self.shieldActive = false

  self.cooldownTime = self.cooldownTime or 1
  self.cooldownTimer = self.cooldownTime

  self.riotShieldParameters = sb.jsonMerge({
    shieldPoly = {{0, -2}, {0, 2}},
    blockFailChance = 0.05,
    blockFailDuration = 0.1
  }, self.riotShieldParameters)

  self.offsets = {
    base = config.getParameter("baseOffset", {0, 0}),
    underbarrel = config.getParameter("underbarrelOffset", {0, 0})
  }
  
  self.riotShieldDamageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.hitType == "ShieldHit" then
        animator.playSound("block")        
        if self.blockFailTimer == 0 and math.random() < self.riotShieldParameters.blockFailChance then
          animator.playSound("break")
          self.blockFailTimer = self.riotShieldParameters.blockFailDuration
          activeItem.setItemShieldPolys({})
        end
        return
      end
    end
  end)

  self.blockFailTimer = 0

end

function Project45Armadillo:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function Project45Armadillo:update(dt, fireMode, shiftHeld)
    
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self:updateRiotShield()

  if not self:triggering() then
    self.triggered = false
  end

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self:triggering()
  and not self.triggered
  and self.cooldownTimer == 0
  then
    if self:isShieldActive()
    then
      self:deactivateShield()
    elseif not status.resourceLocked("energy")
    then
      self:activateShield()
    end
    self.triggered = true
  end
end


function Project45Armadillo:updateRiotShield()

  self.blockFailTimer = math.max(0, self.blockFailTimer - self.dt)
  
  if self.blockFailTimer > 0 then
    activeItem.setItemShieldPolys({})
    return
  end

  local shieldPoly = self.riotShieldParameters.shieldPoly
  shieldPoly = poly.translate(shieldPoly, self.offsets.underbarrel)
  shieldPoly = poly.translate(shieldPoly, self.weapon.weaponOffset)
  shieldPoly = poly.rotate(shieldPoly, self.weapon.relativeWeaponRotation)
  activeItem.setItemShieldPolys({shieldPoly})

  self.riotShieldDamageListener:update()
end

function Project45Armadillo:isShieldActive()
  local statEffects = status.activeUniqueStatusEffectSummary()
  for _, effect in ipairs(statEffects) do
    if effect[1] == "project45armadilloeffect" then
      return true
    end
  end
  return false
end

function Project45Armadillo:activateShield()
  status.addEphemeralEffect("project45armadilloeffect", status.resourceMax("energy")/10, activeItem.ownerEntityId())
  status.overConsumeResource("energy", status.resourceMax("energy"))
  self.cooldownTimer = self.cooldownTime
end

function Project45Armadillo:deactivateShield()
  status.removeEphemeralEffect("project45armadilloeffect")
end

function Project45Armadillo:uninit()
end