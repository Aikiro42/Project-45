require "/scripts/util.lua"
require "/items/active/weapons/project45neoweapon.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/project45gunfire.lua"
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

  self.origConfig = {}

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

  -- reset functions
  for _, f in ipairs({
    "fireProjectile",
    "firePosition",
    "muzzlePosition",
    "aimVector",
  }) do
      self:setParameter(f, Project45GunFire[f])
  end
  self.weapon.damageSource = Weapon.damageSource
  
  -- clear projectile stack
  activeItem.setScriptedAnimationParameter("projectileStack", {})

  -- get ammo percent before change
  local ammoPercent = storage.project45GunState.ammo / self:getParameter("maxAmmo")

  -- apply changes
  if not altConfig then
    self:resetConfig()
    -- clear alt marker
    storage.gunfireSwitchMarker = ""
  else
    for param, newVal in pairs(altConfig) do
      self:setParameter(param, newVal)
    end

    -- set alt marker
    if self.modeLabels[self.modeIndex] then
      storage.gunfireSwitchMarker = self.modeLabels[self.modeIndex]
    else
      -- FIXME: limited to 26 discernible modes
      storage.gunfireSwitchMarker = string.char(64 + (self.modeIndex % 26))
    end

  end

  -- reset ammo
  storage.project45GunState.ammo = math.floor(ammoPercent * self:getParameter("maxAmmo"))

  self.weapon.abilities[self.abilityIndex]:init()

end

function Project45GunFireSwitch:setParameter(param, val)
  if not self.origConfig[param] then
    if not self.weapon.abilities[self.abilityIndex][param] then
      table.insert(self.nilParams, param)
    else
      self.origConfig[param] = self.weapon.abilities[self.abilityIndex][param]
    end
  end
  self.weapon.abilities[self.abilityIndex][param] = val
end

function Project45GunFireSwitch:getParameter(param, getOriginal)
  if getOriginal then -- return original value of param
    return self.origConfig[param]
  else -- return current value of param
    return self.weapon.abilities[self.abilityIndex][param]
  end
end

function Project45GunFireSwitch:resetConfig()
  for param, origVal in pairs(self.origConfig) do
    self.weapon.abilities[self.abilityIndex][param] = origVal
  end
  for _, nilParam in ipairs(self.nilParams) do
    self.weapon.abilities[self.abilityIndex][nilParam] = nil
  end
end

function Project45GunFireSwitch:uninit()
end
