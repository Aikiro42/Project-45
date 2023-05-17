require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

function apply(input)

  -- do not install mod if the thing this mod is applied to isn't my gun
  -- todo: make this variable more unique
  local modInfo = input.parameters.project45GunModInfo
  if not modInfo then return end

  local augment = config.getParameter("augment")
  local output = Item.new(input)
  
  -- if augment field exists, do something
  if augment then
    
    -- retrieve occupied slots
    local modSlots = input.parameters.modSlots or {}
    
    -- get list of accepted mod slots
    local acceptsModSlot = modInfo.acceptsModSlot or {}
    acceptsModSlot.intrinsic = true

    -- MOD INSTALLATION GATES

    -- do not install mod if mod is not part of weapon category
    if augment.category ~= "universal" then
      if modInfo.category ~= augment.category then return end
    end

    -- do not install mod if gun denies installation on slot
    if not acceptsModSlot[augment.slot] then return end    

    -- do not install mod if slot is occupied
    if modSlots[augment.slot] then return end

    -- do not install mod if ability is already installed
    if modSlots.ability then return end

    -- MOD INSTALLATION PROCESS

    -- prepare tables to alter stats and the primary ability in general
    local oldPrimaryAbility = output.config.primaryAbility or {} -- retrieve old primary ability
    local newPrimaryAbility = input.parameters.primaryAbility or {} -- retrieve modified primary ability
    
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
    
    output:setInstanceValue("modSlots", modSlots)
    output:setInstanceValue("isModded", true)

    return output:descriptor(), 1
  
  end
end