require "/scripts/augments/item.lua"
require "/scripts/set.lua"
require "/scripts/util.lua"

Checker = {}

function Checker:new(input, augmentConfig)
  self.input = input
  self.output = Item.new(input)
  self.modSlots = self.output:instanceValue("modSlots", {})
  self.config = augmentConfig
  self.modInfo = self.output:instanceValue("project45GunModInfo")
  self.augment = self.config.getParameter("augment")
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

  if self.checked ~= nil then return self.checked end
  
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
  local acceptsModSlot = modInfo.acceptsModSlot or {}
  set.insert(acceptsModSlot, "ability")
  set.insert(acceptsModSlot, "passive")
  set.insert(acceptsModSlot, "intrinsic")
  if not acceptsModSlot[augment.slot] then
    self:addError(string.format("Weapon does not accept %s mods", augment.slot))
    self.checked = false
  end

  -- Bad weapon if RELEVANT slots are occupied
  local modSlots = self.modSlots
  if modSlots[augment.slot] then return end
  if (augment.ability and modSlots.ability)
  or (augment.passive and modSlots.passive)
  or ((augment.ammo or augment.conversion) and modSlots.ammo)
  then
    local occupiedSlot = augment.slot
    if modSlots.ability then
      occupiedSlot = occupiedSlot + ", ability"
    end
    if modSlots.passive then
      occupiedSlot = occupiedSlot + ", passive"
    end
    if modSlots.ammo then
      occupiedSlot = occupiedSlot + ", ammo"
    end
    self:addError(string.format("%s slot occupied", occupiedSlot))
    self.checked = false
  end

  -- Bad if capacity is not enough
  local upgradeCost = augment.cost or 1
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

  if not compatible then 
    -- Bad if mod has exclusive compatibility and is incompatible with weapon
    if augment.exclusiveCompatibility then
      self:addError(string.format("Weapon incompatible with mod"))
      self.checked = false
  
    -- Bad if non-universal mod and weapon don't share the same category
    elseif augment.category ~= "universal"
      and modInfo.category ~= "universal"
      and augment.category ~= modInfo.category 
      then
        self:addError(string.format("Category mismatch"))
        self.checked = false
      end
  end

  self.checked = true

  return self.checked

end

-- TODO:
function Checker:checkAbility()
end
function Checker:checkConversion()
end
function Checker:checkAmmo()
end
function Checker:checkPassive()
end
function Checker:checkStat()
end