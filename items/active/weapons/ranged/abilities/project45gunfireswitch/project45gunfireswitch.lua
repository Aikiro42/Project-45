require "/scripts/util.lua"
require "/items/active/weapons/project45neoweapon.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45GunFireSwitch = WeaponAbility:new()

function Project45GunFireSwitch:init()

  -- find altAbility
  for i, ability in ipairs(self.weapon.abilities) do
    if ability.name == "_Project45GunFire_" then
      self.abilityIndex = i
      break
    end
  end

  -- initialize mode setting
  self.modeIndex = 0
  self.modes[0] = {}
  self.nilParams = {nil}
  
end

function Project45GunFireSwitch:update(dt, fireMode, shiftHeld)

  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
    self.triggered = false
  end

  if self.fireMode == "alt" and not self.triggered then
    -- triggered; switch modes
    animator.playSound("click")
    self.modeIndex = (self.modeIndex + 1) % (#self.modes + 1)
    if self.modeIndex ~= 0 then
      self:switch(self.modes[self.modeIndex])      
    else
      self:switch()
    end
    self.triggered = true
  end

end


function Project45GunFireSwitch:switch(altConfig)
  if not altConfig then
    util.mergeTable(self.weapon.abilities[self.abilityIndex], self.modes[0])
    for _, nilParam in ipairs(self.nilParams) do
      self.weapon.abilities[self.abilityIndex][nilParam] = nil
    end
    return
  end
  
  for param, _ in pairs(altConfig) do
    if self.modes[0][param] == nil then
      local val = self.weapon.abilities[self.abilityIndex][param]
      if val == nil then
        table.insert(self.nilParams, param)  
      elseif type(val) == "table" then
        self.modes[0][param] = sb.jsonMerge({}, val)
      else
        self.modes[0][param] = val
      end
    end
  end
  util.mergeTable(self.weapon.abilities[self.abilityIndex], altConfig)
  -- self.weapon.forceReset = true
end

function Project45GunFireSwitch:uninit()
end
