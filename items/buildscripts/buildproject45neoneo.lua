require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/project45abilities.lua"

function build(directory, config, parameters, level, seed)
  
  local generalConfig = root.assetJson("/configs/project45/project45_generalconfig.config")
  
  parameters = parameters or {}
  parameters.primaryAbility = parameters.primaryAbility or {}

  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end

  local primaryAbility = function(keyName, defaultValue, set)
    if set then
      config.primaryAbility[keyName] = defaultValue
    else
      if parameters.primaryAbility[keyName] ~= nil then
        return parameters.primaryAbility[keyName]
      elseif config.primaryAbility[keyName] ~= nil then
        return config.primaryAbility[keyName]
      else
        return defaultValue
      end
    end
  end

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end
  -- calculate mod capacity
  construct(config, "project45GunModInfo")
  construct(parameters, "project45GunModInfo")
  parameters.project45GunModInfo.upgradeCapacity = (config.project45GunModInfo.upgradeCapacity or 0) + ((configParameter("level", 1) - 1) * 2)
  
  -- recalculate rarity
  local rarityLevel = configParameter("level", 1)/10
  local levelRarityAssoc = {"Common", "Uncommon", "Rare", "Legendary", "Essential"}
  local rarityLevelAssoc = {Essential=1,Legendary=0.8,Rare=0.6,Uncommon=0.4,Common=0.2}
  if rarityLevelAssoc[configParameter("rarity", "Common")] < rarityLevel then
    parameters.rarity = levelRarityAssoc[math.ceil(rarityLevel * #levelRarityAssoc)]
  end

  parameters.shortdescription = configParameter("shortdescription", "?")
  parameters.project45GunModInfo = configParameter("project45GunModInfo")
  
  if configParameter("level", 1) >= 10 then
    parameters.shortdescription = config.shortdescription .. " ^yellow;^reset;"
  end


  -- retrieve ability animation scripts
  local primaryAnimationScripts = setupAbility(config, parameters, "primary")
  local altAnimationScripts = setupAbility(config, parameters, "alt")

  -- append config animation scripts
  -- to altAnimationScripts
  -- (if anything is appended, altAnimationScripts is usually empty)
  for i, animationScript in ipairs(config.animationScripts or {}) do
    if not project45util.isItemInList(altAnimationScripts, animationScript) then
      table.insert(altAnimationScripts, animationScript)
    end
  end

  -- append primary animation scripts
  -- to altAnimationScripts
  for i, animationScript in ipairs(primaryAnimationScripts) do
    if not project45util.isItemInList(altAnimationScripts, animationScript) then
      table.insert(altAnimationScripts, animationScript)
    end
  end
  
  config.animationScripts = altAnimationScripts
  
  -- elemental type and config (for alt ability)
  local elementalType = configParameter("elementalType", "physical")

  replacePatternInData(config, nil, "<elementalType>", elementalType)
  if config.altAbility and config.altAbility.elementalConfig then
    util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType])
  end

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1)) * generalConfig.globalDamageMultiplier
  
  -- palette swaps
  config.paletteSwaps = ""
  if config.palette then
    local palette = root.assetJson(util.absolutePath(directory, config.palette))
    local selectedSwaps = palette.swaps[configParameter("colorIndex", 1)]
    for k, v in pairs(selectedSwaps) do
      config.paletteSwaps = string.format("%s?replace=%s=%s", config.paletteSwaps, k, v)
    end
  end
  if type(config.inventoryIcon) == "string" then
    config.inventoryIcon = config.inventoryIcon .. config.paletteSwaps
  else
    for i, drawable in ipairs(config.inventoryIcon) do
      if drawable.image then drawable.image = drawable.image .. config.paletteSwaps end
    end
  end

  construct(config, "animationCustom", "lights", "muzzleFlash", "color")
  config.animationCustom.lights.muzzleFlash.color = parameters.muzzleFlashColor or config.muzzleFlashColor or {255, 255, 200}

  construct(config, "animationParts")
  config.animationParts.muzzleFlash = config.animationParts.muzzleFlash or "/items/active/weapons/ranged/project45-muzzleflash.png"

  -- gun offsets
  if config.baseOffset then

    local parts = {
      "middle",
      "charge",
      "magazine"
    }

    for _, part in ipairs(parts) do
      construct(config, "animationCustom", "animatedParts", "parts", part, "properties")
      config.animationCustom.animatedParts.parts[part].properties.offset = config.baseOffset
      construct(config, "animationCustom", "animatedParts", "parts", part .. "Fullbright", "properties")
      config.animationCustom.animatedParts.parts[part .. "Fullbright"].properties.offset = config.baseOffset
    end

    -- set transformation group offsets
    -- muzzle, ejection port, magazine
    local offsetConfig = {
      "muzzleOffset",
      "altMuzzleOffset",
      "ejectionPortOffset",
      "magazineOffset"
    }
    for _, part in ipairs(offsetConfig) do
      if config[part] then
        config[part] = vec2.add(config[part], config.baseOffset)
      end
    end

    if config.chargeSmokeOffsetRegion then
      construct(config, "animationCustom", "particleEmitters", "chargeSmoke", "offsetRegion")
      config.animationCustom.particleEmitters.chargeSmoke.offsetRegion = config.chargeSmokeOffsetRegion
    end

    -- generate offsets for
    -- rail, sights, underbarrel, stock

    local modParts = {
      "rail",
      "sights",
      "underbarrel",
      "stock"
    }

    for _, modPart in ipairs(modParts) do
      if config[modPart .. "Offset"] then
          config[modPart .. "Offset"] = vec2.add(config.baseOffset, config[modPart .. "Offset"])
          construct(config, "animationCustom", "animatedParts", "parts", modPart, "properties")
          construct(config, "animationCustom", "animatedParts", "parts", modPart .. "Fullbright", "properties")
          local modPartOffset = config.animationCustom.animatedParts.parts[modPart].properties.offset or {0, 0}
          local finalModPartOffset = vec2.add(modPartOffset, config[modPart .. "Offset"])
          config.animationCustom.animatedParts.parts[modPart].properties.offset = finalModPartOffset
          config.animationCustom.animatedParts.parts[modPart .. "Fullbright"].properties.offset = finalModPartOffset
      end
    end
    
    -- Underbarrel gun stuff
    construct(config, "animationCustom", "animatedParts", "parts", "underbarrel", "properties")
    if config.animationCustom.animatedParts.parts.underbarrel.properties.firePosition then

      -- move transformation group "altmuzzle", which will be based on altMuzzleOffset
      config.altMuzzleOffset = vec2.add(
        config.altMuzzleOffset or {0, 0},
        config.animationCustom.animatedParts.parts.underbarrel.properties.offset
      )

      config.altMuzzleOffset = vec2.add(
        config.altMuzzleOffset,
        config.animationCustom.animatedParts.parts.underbarrel.properties.firePosition
      )

      -- offset alt muzzle flash
      construct(config, "animationCustom", "animatedParts", "parts", "altMuzzleFlash", "properties")
      config.animationCustom.animatedParts.parts.altMuzzleFlash.properties.offset = vec2.add(
        config.animationCustom.animatedParts.parts.altMuzzleFlash.properties.offset or {0, 0},
        config.animationCustom.animatedParts.parts.underbarrel.properties.firePosition
      )

    end

  end

  if config.primaryAbility then

    -- sync cycle animation
    local fireTimeRelatedStates = {
      "ejecting",
      "feeding"
    }
    local cycleTime = primaryAbility("cycleTime", 0.1)
    if type(cycleTime) == "table" then
      cycleTime = math.min(cycleTime[1], cycleTime[2])
    end
    local stateCycleTime = cycleTime / (#fireTimeRelatedStates + (primaryAbility("loopFiringAnimation", false) and 0 or 1))
    for _, state in ipairs(fireTimeRelatedStates) do
      construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", state)
      config.animationCustom.animatedParts.stateTypes.gun.states[state].cycle = stateCycleTime
      -- sb.logInfo(config.animationCustom.animatedParts.stateTypes.gun.states[state].cycle)
    end

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "firing")
    config.animationCustom.animatedParts.stateTypes.gun.states.firing.cycle = primaryAbility("loopFiringAnimation", false) and cycleTime or stateCycleTime

    construct(config, "animationCustom", "animatedParts", "stateTypes", "charge", "states", "charging")
    config.animationCustom.animatedParts.stateTypes.charge.states.charging.cycle = math.max(0.05, cycleTime)

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "boltPulling")
    config.animationCustom.animatedParts.stateTypes.gun.states.boltPulling.cycle = primaryAbility("cockTime", 0.1)/2

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "unjamming")
    config.animationCustom.animatedParts.stateTypes.gun.states.unjamming.cycle = primaryAbility("cockTime", 0.1)/2

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "boltPushing")
    config.animationCustom.animatedParts.stateTypes.gun.states.boltPushing.cycle = primaryAbility("cockTime", 0.1)/2

  end

  -- tooltip
  -- populate tooltip fields
  if config.tooltipKind == "project45gun" then
    config.tooltipFields = config.tooltipFields or {}
    config.tooltipFields.subtitle = project45util.categoryStrings[config.project45GunModInfo.category or "Generic"] -- .. "^#D1D1D1;" .. config.gunArchetype or config.category
    config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)

    local modList = parameters.modSlots or config.modSlots or {}
    if config.project45GunModInfo then
      local acceptedModSlots = set.new(config.project45GunModInfo.acceptsModSlot or {})
      local mods = {
        "sights",
        "rail",
        "muzzle",
        "underbarrel",
        "stock"
      }
      for _, modSlot in ipairs(mods) do
        if acceptedModSlots[modSlot] then
          config.tooltipFields[modSlot .. "Image"] = modList[modSlot] and modList[modSlot][3] or ""
        end
      end
      
      if not (
        #(config.project45GunModInfo.allowsConversion or {}) == 0
        and #(config.project45GunModInfo.acceptsAmmoArchetype or {}) == 0
      )
      then
        config.tooltipFields.ammoTypeImage = modList.ammoType and modList.ammoType[3] or ""        
      end

    end
    
    if config.primaryAbility then
      
      if config.project45GunModInfo and config.project45GunModInfo.upgradeCapacity
      then
        if config.project45GunModInfo.upgradeCapacity > -1 then
          local count = parameters.upgradeCount or 0
          local max = parameters.project45GunModInfo.upgradeCapacity
          config.tooltipFields.upgradeCapacityLabel = (count < max and "^#96cbe7;" or "^#777777;") .. (max - count) .. "/" .. max .. "^reset;"
        else
          config.tooltipFields.upgradeCapacityLabel = project45util.colorText("#96cbe7","Unlimited")
        end
      else
        config.tooltipFields.upgradeCapacityLabel = project45util.colorText("#777777", "0/0")
      end

      -- recalculate baseDamage
      if config.gunArchetype then
        local archetypeDamage = generalConfig.gunArchetypeDamages[config.gunArchetype]
        -- sb.logInfo(string.format("%s (%s): %s",config.shortdescription, config.gunArchetype, sb.printJson(archetypeDamage)))
        config.primaryAbility.baseDamage = archetypeDamage or config.primaryAbility.baseDamage
      end
        
      -- damage per shot
      -- recalculate
      local baseDamage = primaryAbility("baseDamage", 0) * config.damageLevelMultiplier
      -- low damage = base damage * worst reload damage
      local loDamage = baseDamage
        * math.min(table.unpack(primaryAbility("reloadRatingDamageMults", {0,0,0,0})))
      -- high damage = base damage * best reload damage * last shot damage mult * overcharge mult
      local hiDamage = baseDamage
        * math.max(table.unpack(primaryAbility("reloadRatingDamageMults", {0,0,0,0})))
        * primaryAbility("lastShotDamageMult", 1)
        * (primaryAbility("overchargeTime", 0) > 0 and (primaryAbility("perfectChargeDamageMult") or 2) or 1)
      

      config.tooltipFields.damagePerShotLabel = project45util.colorText("#FF9000", util.round(loDamage, 1) .. " - " .. util.round(hiDamage, 1))
      
      if primaryAbility("debug") then
        config.tooltipFields.damagePerShotLabel = project45util.colorText("#FF9000", primaryAbility("baseDamage", 0))
      end
      
      --[[ fire time calculation:
      If gun is manualFeed:
        fireTime* = cockTime + fireTime
      else:
        fireTime* = cycleTime + fireTime
      
      ]]--
      
      local actualCycleTime = primaryAbility("manualFeed", false)
        and primaryAbility("cockTime", 0.1)
        or primaryAbility("cycleTime", 0.1)
      
      if type(actualCycleTime) ~= "table" then
        actualCycleTime = {actualCycleTime, actualCycleTime}
      end
      
      local loFireTime = actualCycleTime[1] + primaryAbility("fireTime", 0.1)
      local hiFireTime = actualCycleTime[2] + primaryAbility("fireTime", 0.1)
      if loFireTime == hiFireTime then
        config.tooltipFields.fireTimeLabel = project45util.colorText("#FFD400", util.round(loFireTime*1000, 1) .. "ms")
      else
        config.tooltipFields.fireTimeLabel = project45util.colorText("#FFD400",
          util.round(loFireTime*1000, 1) .. " - " .. util.round(hiFireTime*1000, 1) .. "ms")
      end
      
      -- reload cost
      config.tooltipFields.reloadCostLabel = project45util.colorText("#b0ff78", util.round(primaryAbility("reloadCost", 0), 1))

      -- reload time
      local bulletReloadTime = primaryAbility("reloadTime", 0.1)
      local bulletsPerReload = primaryAbility("bulletsPerReload", 1)
      local maxAmmo = primaryAbility("maxAmmo")
      local actualReloadTime = bulletReloadTime * math.max(1, maxAmmo / bulletsPerReload)
      
      config.tooltipFields.reloadTimeLabel = util.round((actualReloadTime or 0), 1) .. "s"

      -- crit chance
      local critChance = primaryAbility("critChance", 0)
      if critChance > 0 then
        config.tooltipFields.critChanceLabel = project45util.colorText("#FF6767", util.round(critChance*100, 1) .. "%")
      else
        config.tooltipFields.critChanceLabel = project45util.colorText("#777777", util.round(critChance*100, 1) .. "%")
      end

      -- crit damage
      local critDamage = primaryAbility("critDamageMult", 1)
      if critChance > 0 then
        config.tooltipFields.critDamageLabel = project45util.colorText("#FF6767", util.round(critDamage, 1) .. "x")
      else
        config.tooltipFields.critDamageLabel = project45util.colorText("#777777", util.round(critDamage, 1) .. "x")
      end

      local descriptionScore = 0

      local miscStats = {
        "heavyWeapon",
        "multishot",
        "chargeTime",
        "overchargeTime"
      }

      local heavyDesc = ""
      if primaryAbility("heavyWeapon", false) then
        descriptionScore = descriptionScore + 1
        heavyDesc = project45util.colorText("#FF5050", "Heavy") .. "\n"
      end

      local multishotDesc = ""
      local multishot = primaryAbility("multishot", 1)
      if multishot ~= 1 then
        descriptionScore = descriptionScore + 1
        multishotDesc = project45util.colorText(multishot > 1 and "#9dc6f5" or "#FF5050", util.round(multishot, 1) .. "x multishot") .. "\n"
      end

      local chargeDesc = ""
      if primaryAbility("chargeTime", 0) > 0 then
        descriptionScore = descriptionScore + 1
        chargeDesc = project45util.colorText("#FF5050", util.round(primaryAbility("chargeTime", 0), 1) .. "s charge time.") .. "\n"
      end
        

      local overchargeDesc = ""
      if primaryAbility("overchargeTime", 0) > 0 then
        descriptionScore = descriptionScore + 1
        chargeDesc = project45util.colorText("#9dc6f5", util.round(primaryAbility("overchargeTime", 0), 1) .. "s overcharge.") .. "\n"
      end
      
      local modListDesc = ""
      if modList then
        local exclude = set.new({"ability","rail","sights","muzzle","underbarrel","stock","ammoType"})
        for modSlot, modKind in pairs(modList) do
          if not exclude[modSlot] and modKind[1] ~= "ability" then
            descriptionScore = descriptionScore + 1
            modListDesc = modListDesc .. project45util.colorText("#abfc6d", modKind[1]) .. "\n"
          end
        end
      end

      local finalDescription = heavyDesc .. chargeDesc .. overchargeDesc .. multishotDesc .. modListDesc -- .. config.description
      finalDescription = finalDescription == "" and project45util.colorText("#777777", "No notable qualities.") or finalDescription
      
      descriptionScore = descriptionScore + math.ceil((#config.description)/18)
      
      if descriptionScore <= 7 then
        config.description = config.description .. "\n" .. finalDescription
      else
        config.description = "Highly modified.\n" .. finalDescription
      end

    end

    if parameters.altAbility then
      config.tooltipFields.altAbilityLabel = ("^#ABD2FF;" .. (parameters.altAbility.name or "Unknown"))
    elseif config.altAbility then
      config.tooltipFields.altAbilityLabel = ("^#ABD2FF;" .. (config.altAbility.name or "Unknown"))
    else
      config.tooltipFields.altAbilityLabel = "^#777777;None"
    end

  end

  -- set price
  -- TODO: should this be handled elsewhere?
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))
  parameters.price = config.price -- needed for gunshop

  return config, parameters
end