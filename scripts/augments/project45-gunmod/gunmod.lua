require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

-- General mod application script

function apply(input)

  -- do not install mod if gun has no mod information
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

    -- do not install mod if it does not belong to the weapon category
    if augment.category ~= "universal"
    and modInfo.category ~= "universal"
    and modInfo.category ~= augment.category then return end

    -- do not install mod if gun denies installation of such type/slot
    if not acceptsModSlot[augment.slot] then return end

    -- do not install mod if slot is occupied
    if modSlots[augment.slot] then return end    
    
    -- MOD INSTALLATION PROCESS

    -- prepare tables to alter primary ability
    local oldPrimaryAbility = output.config.primaryAbility or {} -- retrieve old primary ability
    local newPrimaryAbility = input.parameters.primaryAbility or {} -- retrieve modified primary ability
    
    -- replace general primaryability parameters
    -- using json patch-esque operations
    if augment.primaryAbility then

        -- ADJUST SPECIAL CASES FIRST

        if augment.primaryAbility.maxAmmo then
            -- if augment modifies max ammo (only)
            -- and gun reloads entire ammo capacity
            -- modify bulletsPerReload the same amount the same way

            local bpr = newPrimaryAbility.bulletsPerReload or oldPrimaryAbility.bulletsPerReload
            local maxAmmo = newPrimaryAbility.maxAmmo or oldPrimaryAbility.maxAmmo
            if bpr >= maxAmmo
            and not augment.primaryAbility.bulletsPerReload
            then
                augment.primaryAbility.bulletsPerReload = {
                    operation=augment.primaryAbility.maxAmmo.operation,
                    value=augment.primaryAbility.maxAmmo.value
                }
            end

        end

        if augment.primaryAbility.movementSpeedFactor then
            -- if movementSpeedFactor < 1 then reset it first
            local oldmsf = newPrimaryAbility.movementSpeedFactor or oldPrimaryAbility.movementSpeedFactor
            if oldmsf < 1 then
                local afterOp = augment.primaryAbility.movementSpeedFactor
                augment.primaryAbility.movementSpeedFactor = {{
                    operation = "replace",
                    value = 1
                }}
                table.insert(augment.primaryAbility.movementSpeedFactor, afterOp)
            end
        end

        if augment.primaryAbility.jumpHeightFactor then
            -- if jumpHeightFactor < 1 then reset it first
            local oldmsf = newPrimaryAbility.jumpHeightFactor or oldPrimaryAbility.jumpHeightFactor
            if oldmsf < 1 then
                local afterOp = augment.primaryAbility.jumpHeightFactor
                augment.primaryAbility.jumpHeightFactor = {{
                    operation = "replace",
                    value = 1
                }}
                table.insert(augment.primaryAbility.jumpHeightFactor, afterOp)
            end
        end

        if augment.primaryAbility.laser then
            -- if laser is enabled
            -- merge laser config on top of primaryAbility
            -- save for its enabled and alwaysActive fields
            -- since the mod can turn the laser off
            local laser = newPrimaryAbility.laser or oldPrimaryAbility.laser
            if laser and laser.enabled then
                augment.primaryAbility.laser = {augment.primaryAbility.laser}
                laser.enabled = nil
                laser.alwaysActive = nil
                table.insert(augment.primaryAbility.laser, {
                    operation="merge",
                    value=laser
                })
                -- sb.logInfo(#augment.primaryAbility.laser)

            end
        end


        -- GENERAL MODIFICATION
        -- generate new primaryAbility table
        -- to merge into old primaryAbility table
        local newModifications = {} -- table to merge with newPrimaryAbility
        for parameter, operation in pairs(augment.primaryAbility) do
            if #operation > 0 then
                -- if operation is an array of operations
                -- do them in order
                local newValue = newPrimaryAbility[parameter] or oldPrimaryAbility[parameter]
                for _, op in ipairs(operation) do
                    newValue = modify(
                        newValue,
                        op.operation,
                        op.value
                    )
                end
                newModifications[parameter] = newValue
            
            else
                newModifications[parameter] = modify(
                    newPrimaryAbility[parameter] or oldPrimaryAbility[parameter],
                    operation.operation,
                    operation.value
                )    
            end
        end

        -- END OF MODIFICATION
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, newModifications)
      
    end

    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(oldPrimaryAbility, newPrimaryAbility))

    -- for visible weapon parts like grips, etc.

    local newAnimationCustom = nil
    if augment.animationCustom then
      newAnimationCustom = augment.animationCustom -- TESTME: pointer issues
      -- output:setInstanceValue("animationCustom", sb.jsonMerge(input.parameters.animationCustom or {}, augment.animationCustom))
    end

    if augment.sprite then
        newAnimationCustom = newAnimationCustom or {}
        construct(newAnimationCustom, "animatedParts", "parts", augment.slot, "properties")
        newAnimationCustom.animatedParts.parts[augment.slot].properties.zLevel = augment.sprite.zLevel or 0
        newAnimationCustom.animatedParts.parts[augment.slot].properties.centered = true
        newAnimationCustom.animatedParts.parts[augment.slot].properties.transformationGroups = {"weapon"}
        newAnimationCustom.animatedParts.parts[augment.slot].properties.offset = vec2.add(output.config[augment.slot .. "Offset"] or {0, 0}, augment.sprite.offset or {0, 0})
        newAnimationCustom.animatedParts.parts[augment.slot].properties.image = augment.sprite.image .. "<directives>"

        if augment.sprite.imageFullbright then
            construct(newAnimationCustom, "animatedParts", "parts", augment.slot .. "Fullbright", "properties")
            newAnimationCustom.animatedParts.parts[augment.slot .. "Fullbright"].properties.zLevel = (augment.sprite.zLevel or 0) + 1
            newAnimationCustom.animatedParts.parts[augment.slot].properties.centered = true
            newAnimationCustom.animatedParts.parts[augment.slot].properties.transformationGroups = {"weapon"}
            newAnimationCustom.animatedParts.parts[augment.slot].properties.offset = vec2.add(output.config[augment.slot .. "Offset"] or {0, 0}, augment.sprite.offset or {0, 0})
            newAnimationCustom.animatedParts.parts[augment.slot .. "Fullbright"].properties.image = augment.sprite.imageFullbright .. "<directives>"
        end
    end

    -- if custom animation is set then modify
    if newAnimationCustom then
        output:setInstanceValue("animationCustom", sb.jsonMerge(input.parameters.animationCustom or {}, newAnimationCustom))
    end

    -- for visual muzzle mods
    if augment.muzzleOffset then
        local oldMuzzleOffset = output:instanceValue("muzzleOffset")
        output:setInstanceValue("muzzleOffset", vec2.add(oldMuzzleOffset, augment.muzzleOffset))
    end

    -- mods can enable installation of other mods not normally installable on the weapon
    if augment.enableModSlots then
        local newModSlots = {}
        for _, modSlot in pairs(augment.enableModSlots) do       
            newModSlots[modSlot] = true
        end
        modInfo.acceptsModSlot = sb.jsonMerge(modInfo.acceptsModSlot, newModSlots)
    end
    if augment.enableAmmoTypes then
        local newAmmoTypes = {}
        for _, ammoType in pairs(augment.enableAmmoTypes) do       
            newAmmoTypes[ammoType] = true
        end
        modInfo.acceptsAmmoTypes = sb.jsonMerge(modInfo.acceptsAmmoTypes, newAmmoTypes)
    end
    if augment.enableAmmoArchetypes then
        local newAmmoArchetypes = {}
        for _, ammoArchetype in pairs(augment.enableAmmoArchetypes) do
            newAmmoArchetypes[ammoArchetype] = true
        end
        modInfo.acceptsAmmoArcheypes = sb.jsonMerge(modInfo.acceptsAmmoArcheypes, newAmmoArchetypes)
    end
    output:setInstanceValue("project45GunModInfo", modInfo)
  

    -- MODIFICATION POST-MORTEM

    -- add mod info to list of installed mods

    modSlots[augment.slot] = {
        augment.modName,
        config.getParameter("itemName")
    }
    
    local needImage = {
        rail=true,
        sights=true,
        underbarrel=true,
        muzzle=true,
        stock=true
    }
    if needImage[augment.slot] then
        table.insert(modSlots[augment.slot], config.getParameter("inventoryIcon"))
    end
    
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
--
-- Warning: Does not validate whether the old value is a numeric data type
-- if the operation is not a replacement operation.
function modify(oldValue, operation, modValue)
    local newValue

    -- if operation is replacement old value doesn't matter
    -- if old value is null, force replacement - you can't add to or multiply a null value
    -- this is a base case
    if not oldValue or operation == "replace" then
        newValue = modValue

    -- if operation is a merge operation, the tables will be merged.
    elseif operation == "merge"
    then
        if type(modValue) == "table"
        and type(oldValue) == "table" then
            newValue = sb.jsonMerge(oldValue, modValue)
        end
    
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
        elseif operation == "multiply" then
            newValue = oldValue * modValue
        end

    end

    return newValue
end