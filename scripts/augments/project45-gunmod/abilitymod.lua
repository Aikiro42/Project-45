require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

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
    table.insert(acceptsModSlot, "intrinsic")
    table.insert(acceptsModSlot, "ability")
    acceptsModSlot = set.new(acceptsModSlot)

    -- MOD INSTALLATION GATES

    -- do not install mod if mod is not part of weapon category
    if augment.category ~= "universal" then
      sb.logError("(abilitymod.lua) Ability mod application failed: category mismatch")
      if modInfo.category ~= augment.category then return end
    end

    -- do not install mod if gun denies installation on slot
    if not acceptsModSlot[augment.slot] then
      sb.logError("(abilitymod.lua) Ability mod application failed: gun disallows mod slot")
      return
    end    

    -- do not install mod if slot is occupied
    if modSlots[augment.slot] then
      sb.logError("(abilitymod.lua) Ability mod application failed: something already installed in slot")
      return
    end

    -- do not install mod if ability is already installed
    if modSlots.ability or input.parameters.altAbilityType or (output.config.altAbilityType or output.config.altAbility) then
      sb.logError("(abilitymod.lua) Ability mod application failed: something already installed in ability")
      return
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

    -- sprite visuals
    local newAnimationCustom = nil
    if augment.animationCustom then
      newAnimationCustom = copy(augment.animationCustom)
      -- output:setInstanceValue("animationCustom", sb.jsonMerge(input.parameters.animationCustom or {}, augment.animationCustom))
    end

    -- TESTME:
    -- usually sprites that come with the ability are set up in the weaponability file
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

      newAnimationCustom.animatedParts.parts[augment.slot].properties.offset = vec2.add(output.config[augment.slot .. "Offset"] or {0, 0}, augment.sprite.offset or {0, 0})
      newAnimationCustom.animatedParts.parts[augment.slot].properties.image = augment.sprite.image .. flipDirective .. "<directives>"

      if augment.sprite.imageFullbright then
          construct(newAnimationCustom, "animatedParts", "parts", augment.slot .. "Fullbright", "properties")
          newAnimationCustom.animatedParts.parts[augment.slot .. "Fullbright"].properties.zLevel = (augment.sprite.zLevel or 0) + 1
          newAnimationCustom.animatedParts.parts[augment.slot].properties.centered = true
          newAnimationCustom.animatedParts.parts[augment.slot].properties.transformationGroups = {"weapon"}
          newAnimationCustom.animatedParts.parts[augment.slot].properties.offset = vec2.add(output.config[augment.slot .. "Offset"] or {0, 0}, augment.sprite.offset or {0, 0})
          newAnimationCustom.animatedParts.parts[augment.slot .. "Fullbright"].properties.image = augment.sprite.imageFullbright .. flipDirective .. "<directives>"
      end
    else
      -- if the sprite is set up in the weaponability and we need to fiddle with it,
      -- we need to retrieve the custom animation from the item's config or parameters
      if flipSlots[augment.slot] then

        newAnimationCustom = newAnimationCustom or {}
        construct(newAnimationCustom, "animatedParts", "parts", augment.slot, "properties")
        
        local newPartImage = newAnimationCustom.animatedParts.parts[augment.slot].properties.image
        newPartImage = newPartImage and newPartImage .. "?flipy" or newPartImage
        
        local newPartOffset = newAnimationCustom.animatedParts.parts[augment.slot].properties.offset
        newPartOffset = newPartOffset and vec2.mul(newPartOffset, {1, -1}) or newPartOffset

        newAnimationCustom.animatedParts.parts[augment.slot].properties.image = newPartImage
        newAnimationCustom.animatedParts.parts[augment.slot .. "Fullbright"].properties.image = newPartImage
        newAnimationCustom.animatedParts.parts[augment.slot].properties.offset = newPartOffset
        newAnimationCustom.animatedParts.parts[augment.slot .. "Fullbright"].properties.offset = newPartOffset

      end
    end

    -- if custom animation is set then modify
    if newAnimationCustom then
      output:setInstanceValue("animationCustom", sb.jsonMerge(input.parameters.animationCustom or {}, newAnimationCustom))
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
        table.insert(modSlots.ability, config.getParameter("inventoryIcon"))
        table.insert(modSlots[augment.slot], config.getParameter("inventoryIcon"))
    end
    output:setInstanceValue("modSlots", modSlots)
    output:setInstanceValue("isModded", true)

    return output:descriptor(), 1
  
  end
end