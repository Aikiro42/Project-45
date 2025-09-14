require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"

-- General mod application script

function apply(output, augment)

  local input = output:descriptor()
  local modInfo = output:instanceValue("project45GunModInfo")

  if augment then

    -- prepare tables to alter primary ability
    local oldPrimaryAbility = output.config.primaryAbility or {} -- retrieve old primary ability
    local newPrimaryAbility = input.parameters.primaryAbility or {} -- retrieve modified primary ability
    oldPrimaryAbility = sb.jsonMerge(oldPrimaryAbility, newPrimaryAbility)

    -- replace general primaryability parameters
    -- using json patch-esque operations
    if augment.primaryAbility then

      -- ADJUST SPECIAL CASES FIRST
      if augment.primaryAbility.laser then
        -- if laser is enabled
        -- merge laser config on top of primaryAbility
        -- save for its enabled and alwaysActive fields
        -- since the mod can turn the laser off
        local laser = newPrimaryAbility.laser or oldPrimaryAbility.laser
        if laser and laser.enabled then
          -- compare more vivid color first
          if laser.color and augment.primaryAbility.laser.value.color then
            laser.color = project45util.moreVividColor(laser.color, augment.primaryAbility.laser.value.color)
          end

          -- compare thicker laser first
          if laser.width and augment.primaryAbility.laser.value.width then
            laser.width = math.max(laser.width, augment.primaryAbility.laser.value.width)
          end

          augment.primaryAbility.laser = {augment.primaryAbility.laser}
          laser.enabled = nil
          laser.alwaysActive = nil

          table.insert(augment.primaryAbility.laser, {
            operation = "merge",
            value = laser
          })
          -- sb.logInfo(#augment.primaryAbility.laser)

        end
      end

      if augment.primaryAbility.heavyWeapon and newPrimaryAbility.heavyWeapon == false then
        augment.primaryAbility.heavyWeapon = nil
      end

      local protectedParameters = root.assetJson("/configs/project45/project45_generalstat.config:statDefaults")
      -- protect gun from getting their stats modified directly
      for param, _ in pairs(protectedParameters) do
        augment.primaryAbility[param] = nil
      end
      augment.level = nil

      -- GENERAL MODIFICATION
      -- generate new primaryAbility table
      -- to merge into old primaryAbility table
      local newModifications = {} -- table to merge with newPrimaryAbility
      for parameter, operation in pairs(augment.primaryAbility) do
        if #operation > 0 then
          -- if operation is an array of operations
          -- check and do them in order
          local newValue = newPrimaryAbility[parameter] or oldPrimaryAbility[parameter]
          for _, op in ipairs(operation) do
            if project45util.doOperationChecks(input.parameters, op.checks or {}) then
              newValue = modify(newValue, op.operation, op.value)
            end
          end
          newModifications[parameter] = newValue

        else
          if project45util.doOperationChecks(input.parameters, operation.checks or {}) then
            newModifications[parameter] = modify(newPrimaryAbility[parameter] or oldPrimaryAbility[parameter],
                operation.operation, operation.value)
          end
        end
      end

      -- END OF MODIFICATION
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, newModifications)

    end

    -- merge changes
    -- local finalPrimaryAbility = sb.jsonMerge(oldPrimaryAbility, newPrimaryAbility)
    -- sb.logInfo("(gunmod.lua) new parameters: " .. sb.printJson(finalPrimaryAbility))
    output:setInstanceValue("primaryAbility", newPrimaryAbility)

    -- for visible weapon parts like grips, etc.

    local newAnimationCustom = nil
    if augment.animationCustom then
      newAnimationCustom = copy(augment.animationCustom)
      -- output:setInstanceValue("animationCustom", sb.jsonMerge(input.parameters.animationCustom or {}, augment.animationCustom))
    end

    local flipSlots = set.new(modInfo.flipSlot or {})
    if augment.sprite then
      newAnimationCustom = newAnimationCustom or {}

      construct(newAnimationCustom, "animatedParts", "parts", augment.slot, "properties")
      
      newAnimationCustom.animatedParts.parts[augment.slot].properties.zLevel = augment.sprite.zLevel or 0
      newAnimationCustom.animatedParts.parts[augment.slot].properties.centered = true
      newAnimationCustom.animatedParts.parts[augment.slot].properties.transformationGroups = {"weapon"}

      local flipDirective = ""
      if flipSlots[augment.slot] then
        flipDirective = "?flipy"
        augment.sprite.offset = augment.sprite.offset and vec2.mul(augment.sprite.offset, {1, -1}) or {0, 0}
      end

      newAnimationCustom.animatedParts.parts[augment.slot].properties.offset = vec2.add(
          output.config[augment.slot .. "Offset"] or {0, 0}, augment.sprite.offset or {0, 0})
      newAnimationCustom.animatedParts.parts[augment.slot].properties.image =
          augment.sprite.image .. flipDirective .. "<directives>"

      if augment.sprite.imageFullbright then
        
        local fullbrightSlot = augment.slot .. "Fullbright"

        construct(newAnimationCustom, "animatedParts", "parts", fullbrightSlot, "properties")
        
        newAnimationCustom.animatedParts.parts[fullbrightSlot].properties.zLevel = (augment.sprite.zLevel or 0) + 1
        newAnimationCustom.animatedParts.parts[fullbrightSlot].properties.centered = true
        newAnimationCustom.animatedParts.parts[fullbrightSlot].properties.transformationGroups = {"weapon"}
        newAnimationCustom.animatedParts.parts[fullbrightSlot].properties.fullbright = true
        
        newAnimationCustom.animatedParts.parts[fullbrightSlot].properties.offset = vec2.add(
            output.config[augment.slot .. "Offset"] or {0, 0}, augment.sprite.offset or {0, 0})
        newAnimationCustom.animatedParts.parts[fullbrightSlot].properties.image =
          augment.sprite.imageFullbright .. flipDirective .. "<directives>"
      end
    elseif flipSlots[augment.slot] then
      -- if the sprite is set up in the weaponability and we need to fiddle with it,
      -- we need to retrieve the custom animation from the item's config or parameters
      local configAnimationCustom = output.config.animationCustom or {}
      newAnimationCustom = newAnimationCustom or {}

      construct(configAnimationCustom, "animatedParts", "parts", augment.slot, "properties")
      construct(newAnimationCustom, "animatedParts", "parts", augment.slot, "properties")

      local newPartImage = newAnimationCustom.animatedParts.parts[augment.slot].properties.image or
                               configAnimationCustom.animatedParts.parts[augment.slot].properties.image
      newPartImage = newPartImage and newPartImage .. "?flipy" or newPartImage

      local newPartOffset = newAnimationCustom.animatedParts.parts[augment.slot].properties.offset or
                                configAnimationCustom.animatedParts.parts[augment.slot].properties.offset
      newPartOffset = newPartOffset and vec2.mul(newPartOffset, {1, -1}) or newPartOffset

      newAnimationCustom.animatedParts.parts[augment.slot].properties.image = newPartImage
      newAnimationCustom.animatedParts.parts[augment.slot .. "Fullbright"].properties.image = newPartImage
      newAnimationCustom.animatedParts.parts[augment.slot].properties.offset = newPartOffset
      newAnimationCustom.animatedParts.parts[augment.slot .. "Fullbright"].properties.offset = newPartOffset

    end

    -- if custom animation is set then modify
    if newAnimationCustom then
      output:setInstanceValue("animationCustom",
          sb.jsonMerge(input.parameters.animationCustom or {}, newAnimationCustom))
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

    return output

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
  elseif operation == "merge" then
    if type(modValue) == "table" and type(oldValue) == "table" then
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
      newValue = oldValue + modValue
    elseif operation == "multiply" then
      newValue = oldValue * modValue
    
    -- should be used with boolean properties
    elseif operation == "or" then
      newValue = oldValue or newValue
      
    -- must only be used with boolean properties
    elseif operation == "and" then
      newValue = oldValue and newValue
    elseif operation == "not" then
      newValue = not oldValue
    end

  end

  return newValue

end
