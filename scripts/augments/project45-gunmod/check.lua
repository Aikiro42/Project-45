require "/scripts/augments/item.lua"
require "/scripts/set.lua"
require "/scripts/util.lua"
require "/scripts/augments/project45-gunmod/constants.lua"

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

  -- Bad mod/augment if category mismatch
  if modInfo.category ~= "universal"
  and augment.category ~= "universal"
  and modInfo.category ~= augment.category then
    self:addError(string.format("Weapon does not accept %s mods", augment.category))
    self.checked = false
  end

  -- Bad if weapon does not accept mod slot
  local acceptsModSlot = set.new(modInfo.acceptsModSlot or {})
  -- FIXME: is there no set.union or table.append or something?
  for _, slot in ipairs(INNATE_SLOTS) do
    set.insert(acceptsModSlot, slot)
  end
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
  
  -- Check blacklist
  local weaponBlacklist = set.new(augment.incompatibleWeapons or {})
  local augmentBlacklist = set.new(modInfo.incompatibleMods or {})
  local incompatible = weaponBlacklist[input.name] or augmentBlacklist[config.getParameter("itemName")]

  if incompatible then
    -- Bad if augment blacklists weapon
    if weaponBlacklist[input.name] then
      self:addError(string.format("Weapon incompatible with mod"))
      self.checked = false
    end

    -- Bad if weapon blacklists augment
    if augmentBlacklist[config.getParameter("itemName")] then
      self:addError(string.format("Mod incompatible with weapon"))
      self.checked = false
    end
  end

  -- Check whitelist
  local weaponWhitelist = set.new(augment.compatibleWeapons or {})
  local augmentWhitelist = set.new(modInfo.compatibleMods or {})
  local compatible = weaponWhitelist[input.name] or augmentWhitelist[config.getParameter("itemName")]
  self.compatible = compatible and not incompatible

  if not compatible then
    -- non-experimental mods are compatible with experimental weapons
    -- experimental mods are ONLY compatible with experimental weapons
    local experimentalCompatibility =
      augment.category ~= "experimental"
      or (augment.category == "experimental" and modInfo.uniqueType == "experimental")
      or (augment.category == "experimental" and modInfo.category == "experimental")

    -- Bad if mod has exclusive compatibility and is incompatible with weapon
    if augment.exclusiveCompatibility then
      self:addError(string.format("Mod incompatible with weapon"))
      self.checked = false

    -- Bad if non-universal mod and weapon don't share the same category
    elseif augment.category ~= "universal"
      and modInfo.category ~= "universal"
      and augment.category ~= modInfo.category
      and not experimentalCompatibility
      then
      self:addError(string.format("Category mismatch"))
      self.checked = false
    end
  else
    -- Good if whitelisted and not blacklisted
    self.checked = true
  end

  if self.checked == nil then
    self.checked = true
  else
    self.checked = self.checked and true
  end

  return self.checked

end

function Checker:checkAbility()
    
  if not self.augment.ability then
    -- nothing to check
    self.checked = self.checked and true
    return true
  end

  if (self.augment.ability.altAbilityType
  or self.augment.ability.altAbility) then
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

    --[[
    if self.augment.hasShiftAction
    and (self.output:instanceValue("shiftAbility") or self.output:instanceValue("shiftAbilityType"))
    then
      self:addError(string.format("Incompatible with Shift Ability"))
      self.checked = false
      return false
    end
    --]]
  end

  if (self.augment.ability.shiftAbilityType
  or self.augment.ability.shiftAbility) then
    if self.modSlots.shiftAbility then
      self:addError(string.format("Shift Ability slot occupied"))
      self.checked = false
      return false
    end

    if self.output:instanceValue("shiftAbility")
    or self.output:instanceValue("shiftAbilityType")
    then
      self:addError(string.format("Weapon has Shift Ability"))
      self.checked = false
      return false
    end

    --[[
    if self.output:instanceValue("hasShiftAction") then
      self:addError(string.format("Weapon has Shift Action"))
      self.checked = false
      return false
    end
    --]]
  end

  self.checked = self.checked and true
  return true
end

function Checker:checkConversion()
  
  if not self.augment.conversion then
    -- nothing to check
    self.checked = self.checked and true
    return true
  end

  if self.modSlots.ammoType then
    self:addError(string.format("Ammo slot occupied"))
    self.checked = false
    return false
  end

  -- Check if conversion is necessary
  self.conversionNecessary = self.output.primaryAbility.projectileKind ~= self.augment.conversion
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
  
  if not self.augment.ammo then
    -- nothing to check
    self.checked = self.checked and true
    return true
  end

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
  
  if not self.augment.stat then
    -- nothing to check
    self.checked = self.checked and true
    return true
  end

  if self.augment.stat.level and (self.output:instanceValue("level", 1)) >= 10 then
    self:addError("Weapon at max level")
    self.checked = false
    return false
  end

  -- stackLimit only applies to pure stat mods
  if self.augment.pureStatMod
  and self.augment.stat.stackLimit then

    local augmentItemId = self.config.getParameter("itemName", "")
    self.statList = self.statList or self.output:instanceValue("statList", {})
    local installedCount = 0
    if self.augment.stat.randomStatParams then
      local wildcardSeeds = self.statList.wildcards[augmentItemId] or {nil}
      installedCount = #wildcardSeeds    
    else
      installedCount = self.statList[augmentItemId] or 0
    end

    if installedCount >= self.augment.stat.stackLimit then
      self:addError("Max stat mods of type installed")
    end
    
    local passedCheck = installedCount < self.augment.stat.stackLimit
    self.checked = self.checked and passedCheck
    return passedCheck

  end

  self.checked = self.checked and true
  return true

end
