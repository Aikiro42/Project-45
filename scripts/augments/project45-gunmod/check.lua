require "/scripts/augments/item.lua"
require "/scripts/set.lua"
require "/scripts/util.lua"

function print(...)
  sb.logInfo(...)
end
function json(...)
  return sb.printJson(...)
end

Checker = {}

function Checker:new(input, augmentConfig)
  self.input = input
  self.output = Item.new(input)

  self.output.primaryAbility = sb.jsonMerge(self.output.config.primaryAbility, self.output.parameters.primaryAbility or {})

  self.modSlots = self.output:instanceValue("modSlots", {})
  self.config = augmentConfig
  self.modInfo = sb.jsonMerge(self.output.config.project45GunModInfo, self.output:instanceValue("project45GunModInfo"))  
  
  self.statList = self.output:instanceValue("statList", {nil})
  self.statList.wildcards = self.statList.wildcards or {}

  self.augment = self.config.getParameter("augment")

  -- SECTION: VALIDATIONS
  
  -- validate modName
  self.augment.modName = self.augment.modName or self.config.getParameter("shortdescription")

  -- validate cost
  self.augment.cost = self.augment.cost or 0

  -- validate category
  self.augment.category = self.augment.category or "universal"

  -- conversion and projectileKind must be equal
  local conversion = self.augment.conversion
  local projectileKind = (self.augment.ammo or {}).projectileKind

  if projectileKind and not conversion then
    self.augment.conversion = projectileKind
  elseif conversion and (self.augment.ammo and not projectileKind) then
    self.augment.ammo.projectileKind = conversion
  end

  -- validate augment slot
  if not self.augment.slot then
    if self.augment.gun then self.augment.slot = "unknown"
    elseif self.augment.ability then self.augment.slot = "ability"
    elseif self.augment.conversion or self.augment.ammo then self.augment.slot = "ammoType"
    elseif self.augment.passive then self.augment.slot = "passive"
    else self.augment.slot = "stat" end
  end
  
  return self
end

function Checker:addError(error)
  if self.errors == nil then
    self.errors = {error}
  else
    table.insert(self.errors, error)
  end
end

function Checker:getErrorOutputItem()
  local errorOutput = Item.new(self.input)
  errorOutput:setInstanceValue("project45GunFireMessages", self.errors)
  return errorOutput:descriptor()
end

function Checker:customCheckFunction()
end

function Checker:customCheck()
  return self:customCheckFunction()
end

function Checker:check()

  if self.checked ~= nil then
    return self.checked
  end

  local input = self.input
  local output = self.output
  config = self.config

  -- Bad weapon if modInfo absent
  local modInfo = self.modInfo

  if not modInfo then
    self:addError('Missing "project45GunModInfo" field on weapon')
    self.checked = false
    return false
  end

  -- Bad mod if augment absent
  local augment = self.augment
  if not augment then
    self:addError('Missing "augment" field on augment')
    self.checked = false
    return false
  end

  -- Bad if weapon does not accept mod slot
  local acceptsModSlot = set.new(modInfo.acceptsModSlot or {})
  set.insert(acceptsModSlot, "ability")
  set.insert(acceptsModSlot, "passive")
  set.insert(acceptsModSlot, "intrinsic")
  set.insert(acceptsModSlot, "stat")
  set.insert(acceptsModSlot, "ammoType")
  if not acceptsModSlot[augment.slot] then
    self:addError(string.format("Weapon does not accept %s mods", augment.slot))
    self.checked = false
  end

  -- Bad weapon if specified slot is occupied
  local modSlots = self.modSlots
  if modSlots[augment.slot] then
    -- modSlots["stat"] should ALWAYS return false
    self:addError(string.format("%s slot occupied", augment.slot))
    self.checked = false
  end

  -- Bad if capacity is not enough
  local upgradeCost = augment.cost
  local upgradeCapacity = modInfo.upgradeCapacity or -1
  local upgradeCount = output:instanceValue("upgradeCount", 0)
  if upgradeCapacity >= 0 then
    if upgradeCount + upgradeCost > upgradeCapacity then
      self:addError(string.format("Mod does not fit available capacity"))
      self.checked = false
    end
  end

  -- Bad if augment blacklists weapon
  local weaponBlacklist = set.new(augment.incompatibleWeapons or {})
  if weaponBlacklist[input.name] then
    self:addError(string.format("Weapon incompatible with mod"))
    self.checked = false
  end

  -- Bad if weapon blacklists augment
  local augmentBlacklist = set.new(modInfo.incompatibleMods or {})
  if augmentBlacklist[config.getParameter("itemName")] then
    self:addError(string.format("Mod incompatible with weapon"))
    self.checked = false
  end

  -- Check whitelist
  local weaponWhitelist = set.new(augment.compatibleWeapons or {})
  local augmentWhitelist = set.new(modInfo.compatibleMods or {})
  local compatible = weaponWhitelist[input.name] or augmentWhitelist[config.getParameter("itemName")]
  self.compatible = compatible

  if not compatible then
    -- Bad if mod has exclusive compatibility and is incompatible with weapon
    if augment.exclusiveCompatibility then
      self:addError(string.format("Mod incompatible with weapon"))
      self.checked = false

      -- Bad if non-universal mod and weapon don't share the same category
    elseif augment.category ~= "universal" and modInfo.category ~= "universal" and augment.category ~= modInfo.category then
      self:addError(string.format("Category mismatch"))
      self.checked = false
    end
  end

  if self.checked == nil then
    self.checked = true
  else
    self.checked = self.checked and true
  end

  return self.checked

end

function Checker:checkAbility()
  if self.modSlots.ability then
    self:addError(string.format("Ability slot occupied"))
    self.checked = false
    return false
  end

  if self.output:instanceValue("altAbility")
  or self.output:instanceValue("altAbilityType")
  then
    self:addError(string.format("Weapon has ability"))
    self.checked = false
    return false
  end

  self.checked = self.checked and true
  return true
end

function Checker:checkConversion()

  if self.modSlots.ammoType then
    self:addError(string.format("Ammo slot occupied"))
    self.checked = false
    return false
  end

  -- Check if conversion is necessary
  self.conversionNecessary = self.output.primaryAbility.projectileKind ~= self.augment.conversion
  print(json(self.augment.ammo or self.conversionNecessary, 1))
  if self.augment.ammo and not self.conversionNecessary then
    self.checked = self.checked and true
    return true
  end

  -- Bad if conversion is to same type
  local projectileKind = self.output.config.primaryAbility.projectileKind 
  if projectileKind == self.augment.conversion then
    self:addError(string.format("Weapon already fires %s", self.augment.conversion))
    self.checked = false
    return false
  end
  
  -- Bad if doesn't allow conversion
  local conversionWhitelist = set.new(self.modInfo.allowsConversion or {})
  if not conversionWhitelist[self.augment.conversion] then
    self:addError(string.format("Weapon disallows %s conversion", self.augment.conversion))
    self.checked = false
    return false
  end

  -- Bad if invalid conversion
  if not set.new({"projectile", "hitscan", "beam", "summoned"})[self.augment.conversion] then
    self:addError(string.format("Invalid conversion: %s", self.augment.conversion))
    self.checked = false
    return false
  end
  
  self.checked = self.checked and true
  return true
  
end

function Checker:checkAmmo()

  if self.modSlots.ammoType then
    self:addError(string.format("Ammo slot occupied"))
    self.checked = false
    return false
  end

  if not self.compatible then
    local acceptedArchetype = set.new(self.modInfo.acceptsAmmoArchetype)
    if self.augment.ammo.archetype ~= "universal" and not acceptedArchetype["universal"] and
        not acceptedArchetype[self.augment.ammo.archetype] then
      self:addError("Ammo archetype mismatch")
      self.checked = false
      return false
    end
  end
  self.checked = self.checked and true
  return true
end

function Checker:checkPassive()

  -- Deny installation if passive script is already established
  if self.modSlots.passive or self.output:instanceValue("primaryAbility", {}).passiveScript then
    self:addError("Passive already present")
    self.checked = false
    return false
  end

  -- Deny installation if shift action is already established and passive does not override it
  if self.augment.passive.hasShiftAction and self.output:instanceValue("hasShiftAction") and not self.augment.passive.overrideShiftAction then
    self:addError("Shift action already utilized")
    self.checked = false
    return false
  end

  self.checked = self.checked and true
  return true
  
end

function Checker:checkStat()
  
  if self.augment.stat.level and (output:instanceValue("level", 1)) >= 10 then
    self:addError("Weapon at max level")
    self.checked = false
    return false
  end

end
