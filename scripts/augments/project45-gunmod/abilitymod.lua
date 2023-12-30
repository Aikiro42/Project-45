require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/augments/project45-gunmod/gunmod.lua"
require "/scripts/project45/project45util.lua"

local gunmod_apply = apply

function apply(input)

  -- do not install mod if the thing this mod is applied to isn't my gun
  -- TODO: make this variable more unique
  local output = Item.new(input)
  local modInfo = sb.jsonMerge(output.config.project45GunModInfo, input.parameters.project45GunModInfo)
  if not modInfo then return end

  local augment = config.getParameter("augment")
  
  -- if augment field exists, do something
  if augment then
    
    -- retrieve occupied slots
    local modSlots = input.parameters.modSlots or {}
    
    -- get list of accepted mod slots
    local acceptsModSlot = modInfo.acceptsModSlot or {}
    acceptsModSlot = set.new(acceptsModSlot)
    set.insert(acceptsModSlot, "intrinsic")
    set.insert(acceptsModSlot, "ability")

    -- get upgrade cost and prep upgrade capacity variables
    local upgradeCost = augment.upgradeCost
    local upgradeCapacity, upgradeCount


    -- MOD INSTALLATION GATES
    
    -- Deny installation if slot is occupied
    if modSlots[augment.slot] then
      sb.logError("(abilitymod.lua) Ability mod application failed: something already installed in slot")
      return gunmodHelper.addMessage(input, project45util.capitalize(augment.slot) .. " mod slot occupied")
    end

    -- Deny installation if ability is already installed
    if modSlots.ability or input.parameters.altAbilityType or (output.config.altAbilityType or output.config.altAbility) then
      sb.logError("(abilitymod.lua) Ability mod application failed: something already installed in ability")
      return gunmodHelper.addMessage(input, "Weapon has ability")
    end 

    -- Deny installation if upgrade capacity is maxed
    if upgradeCost then
      upgradeCount = input.parameters.upgradeCount or 0
      upgradeCapacity = modInfo.upgradeCapacity or -1
      if upgradeCapacity > -1 and upgradeCount + upgradeCost > upgradeCapacity then
        sb.logError("(abilitymod.lua) Ability mod application failed: Not Enough Upgrade Capacity")
        return gunmodHelper.addMessage(input, "Not Enough Upgrade Capacity")
      end
    end 

    -- deny installation if mod rejects gun
    if augment.incompatibleWeapons then
      local deniedWeapons = set.new(augment.incompatibleWeapons)
      if deniedWeapons[input.name] then
          sb.logError("(abilitymod.lua) Mod application failed: Mod incompatible with " .. input.name .. " (mod rejects gun)")
          return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
      end
    end
    
    -- deny installation if gun rejects mod
    if modInfo.incompatibleMods then
      local deniedMods = set.new(modInfo.incompatibleMods)
      if deniedMods[config.getParameter("itemName")] then
          sb.logError("(abilitymod.lua) Mod application failed: Mod incompatible with " .. input.name .. " (gun rejects mod)")
          return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
      end
    end
    

    local bypassCompatChecks = false

    -- check if mod accepts gun
    if augment.compatibleWeapons then
      local acceptedWeapons = set.new(augment.compatibleWeapons)
      bypassCompatChecks = bypassCompatChecks or acceptedWeapons[input.name]
    end

    -- check if gun accepts mod
    if modInfo.compatibleMods then
      local acceptedMods = set.new(modInfo.compatibleMods)
      bypassCompatChecks = bypassCompatChecks or acceptedMods[config.getParameter("itemName")]
    end

    -- If exclusiveCompatibility and weapon not accepted then
    if augment.exclusiveCompatibility and not bypassCompatChecks then
      sb.logError("(abilitymod.lua) Mod application failed: Mod incompatible with " .. input.name .. " (gun rejects mod)")
      return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
    end

    if not bypassCompatChecks then

      -- do not install mod if augment is not universal
      -- and gun is not of the universal category
      -- and it does not belong to the weapon category
      if augment.category ~= "universal"
      and modInfo.category ~= "universal"
      and modInfo.category ~= augment.category then
        sb.logError("(abilitymod.lua) Ability mod application failed: category mismatch")
        return gunmodHelper.addMessage(input, "Wrong Category: " .. config.getParameter("shortdescription"))
      end
      
      -- do not install mod if gun denies installation on slot
      if not acceptsModSlot[augment.slot] then
        sb.logError("(abilitymod.lua) Ability mod application failed: gun disallows mod slot")
        return gunmodHelper.addMessage(input, "Cannot install " .. augment.slot .. " mods")
      end
      
    end

    -- MOD INSTALLATION PROCESS

    -- prepare tables to alter primary ability
    local oldPrimaryAbility = output.config.primaryAbility or {} -- retrieve old primary ability
    local newPrimaryAbility = input.parameters.primaryAbility or {} -- retrieve modified primary ability
    oldPrimaryAbility = sb.jsonMerge(oldPrimaryAbility, newPrimaryAbility) -- TESTME: merge new primary ability on old
    
    -- alter or set ability type if present
    if augment.altAbilityType and input.parameters.altAbilityType ~= augment.altAbilityType then
    
      output:setInstanceValue("altAbilityType", augment.altAbilityType)

      if augment.overrideTwoHanded then
        output:setInstanceValue("twoHanded", augment.twoHanded)
      end
      
      -- merge ability parameters
      if augment.altAbility then
        output:setInstanceValue("altAbility", sb.jsonMerge(input.parameters.altAbility or {}, augment.altAbility))
      end

    end

    -- MODIFICATION POST-MORTEM

    -- add mod info to list of installed mods
    modSlots.ability = {
        "ability",
        config.getParameter("itemName")
    }
    modSlots[augment.slot] = {
        "ability",
        config.getParameter("itemName")
    }
    
    local needImage = set.new({
      "rail",
      "sights",
      "underbarrel",
      "muzzle",
      "stock"
    })
    if needImage[augment.slot] then
      table.insert(modSlots[augment.slot], config.getParameter("inventoryIcon"))
    end

    output:setInstanceValue("modSlots", modSlots)
    if upgradeCost then
      output:setInstanceValue("upgradeCount", upgradeCount + upgradeCost)
    end

    -- return output:descriptor(), 1
    return gunmod_apply(output, true, augment)
  
  end
end