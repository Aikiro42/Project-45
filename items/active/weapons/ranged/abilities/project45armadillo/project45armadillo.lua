require "/scripts/util.lua"
require "/items/active/weapons/project45neoweapon.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45Armadillo = WeaponAbility:new()

function Project45Armadillo:init()
  self.shieldRadius = self.shieldRadius or 3
  self.shieldOffset = self.shieldOffset or {0, -0.5}
  self.shieldActive = false 

  self.energyDrain = self.energyDrain or 1
  self.energyDrainTimer = 1

end

function Project45Armadillo:update(dt, fireMode, shiftHeld)
    
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
    self.triggered = false
  end

  if self.shieldActive then
    status.addEphemeralEffect("project45armadilloeffect")
    self.energyDrainTimer = math.max(self.energyDrainTimer - self.dt, 0)
    if self.energyDrainTimer <= 0 then
      self.energyDrainTimer = 1
      if not status.overConsumeResource("energy", self.energyDrain) then
        self:deactivate()
      end
    end
  else
    self.energyDrainTimer = 1
  end

  if self.shiftHeld
  and not status.resourceLocked("energy")
  then
    if not self.shieldActive then
      self:activate()
    end
  else
    self:deactivate()
  end

end

function Project45Armadillo:activate()
  self.shieldActive = true
  status.addEphemeralEffect("project45armadilloeffect")
  status.setPersistentEffects("project45armadilloshield", {
    {
      stat = "shieldHealth",
      amount = status.resourceMax("energy") * 2
    },
    {
      stat = "movementSpeedFactor",
      amount = 0  
    },
    {
      stat = "jumpHeightFactor",
      amount = 0  
    }
  })
  local poly = {self:generateShieldPoly(self.shieldRadius, self.shieldOffset)}
  activeItem.setShieldPolys(poly)
end

function Project45Armadillo:deactivate()
  status.clearPersistentEffects("project45armadilloshield")
  status.resetResource("shieldStamina")
  status.removeEphemeralEffect("project45armadilloeffect")
  activeItem.setShieldPolys()
  self.shieldActive = false
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
  self:deactivate()
end