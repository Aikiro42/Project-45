require "/scripts/util.lua"
require "/items/active/weapons/project45neoweapon.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45Armadillo = WeaponAbility:new()

function Project45Armadillo:init()
  self.shieldRadius = self.shieldRadius or 3
  self.shieldOffset = self.shieldOffset or {0, -0.5}
  self.shieldActive = false

  self.cooldownTime = self.cooldownTime or 1
  self.cooldownTimer = self.cooldownTime

end
function Project45Armadillo:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end
function Project45Armadillo:update(dt, fireMode, shiftHeld)
    
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if not self:triggering() then
    self.triggered = false
  end

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  self:updateShieldPoly()

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

function Project45Armadillo:updateShieldPoly()
  -- activeItem.setItemShieldPolys({{-1, -1}, {-1, 1}, {1, 1}, {1, -1}})
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

function Project45Armadillo:generateShieldPoly(radius, shieldOffset, segments)
  segments = segments or 8
  local poly = {}
  local arcAngle = 2*math.pi/segments
  for i=1, segments do
    table.insert(poly, vec2.add(shieldOffset, {radius * math.cos(arcAngle * i), radius * math.sin(arcAngle * i)}))
  end
  return poly
end

function Project45Armadillo:uninit()
end