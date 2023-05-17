require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

function apply(input)

  -- do not install mod if the thing this mod is applied to isn't my gun
  -- todo: make this variable more unique
  if not input.parameters.acceptsGunMods then return end

  local augment = config.getParameter("augment")
  local output = Item.new(input)
  
  -- if augment field exists, do something
  if augment then
    
    -- retrieve occupied slots
    local modSlots = input.parameters.modSlots or {}
    
    -- get list of accepted mod slots
    local acceptsModSlot = output:instanceValue("acceptsModSlot", {})

    -- MOD INSTALLATION GATES

    -- do not install mod if gun denies installation of such type/slot
    if not acceptsModSlot[augment.slot] then return end    

    -- do not install mod if slot is occupied
    if modSlots[augment.slot] then return end
    
    -- Abilities occupy two modslots - the slot they're assigned to, and the "ability" slot.
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
        augment.modName,
        config.getParameter("itemName")
    }
    modSlots[augment.slot] = {
        augment.modName,
        config.getParameter("itemName")
    }
    
    output:setInstanceValue("modSlots", modSlots)
    output:setInstanceValue("isModded", true)

    return output:descriptor(), 1
  
  end
end

-- Returns a modified value given
-- * an operation and
-- * the value to change the old value by.
--
-- If the old value is a table, the operation is applied to all its atomic elements.
function modify(oldValue, operation, modValue)
    local newValue

    -- if operation is replacement old value doesn't matter
    -- this is a base case
    if operation == "replace" then
        newValue = modValue
    
    -- otherwise
    -- if old value is a table recursively modify each
    -- element of the old value table
    elseif type(oldValue) == "table" then
        newValue = {}
        -- for each value in oldValue, modify it
        for key, val in pairs(oldValue) do
            newValue[key] = modify(val, operation, modValue)
        end
    
    -- if old value is atomic, modify as such
    -- this is a base case
    else
        if operation == "add" then
            newValue = oldValue * modValue
        elseif operation == "mult" then
            newValue = oldValue * modValue
        end

    end

    return newValue
end
