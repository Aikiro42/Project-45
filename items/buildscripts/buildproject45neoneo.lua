require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/project45abilities.lua"

function build(directory, config, parameters, level, seed)
  
  local generalConfig = root.assetJson("/configs/project45/project45_general.config")
  local generalTooltipConfig = root.assetJson("/configs/project45/project45_generaltooltip.config")
  
  local rarityConversions = {
    common = project45util.colorText("#96cbe7", "R (Common)"),
    uncommon = project45util.colorText("#96cbe7", "R (Uncommon)"),
    rare = project45util.colorText("#d29ce7", "SR (Rare)"),
    legendary = project45util.colorText("#d29ce7", "SR (Legendary)"),
    essential = project45util.colorText("#ffffa7", "SSR (Essential)"),
    unique = project45util.colorText("#f4988c", "XSSR (UNIQUE)")
  }
  
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
  
  local deepConfigParameterT = function(t, ...)
    local retval = nil
    for _,child in ipairs({...}) do
      if t[child] then
        retval = t[child]
        t = t[child]
      else
        retval = nil
        break
      end
    end
    return retval
  end

  -- Lovechild of construct() and configParameter().
  local deepConfigParameter = function(defaultValue, ...)
    local retval = deepConfigParameterT(parameters, ...)
    if retval ~= nil then return retval end
    retval = deepConfigParameterT(config, ...)
    if retval ~= nil then return retval end
    return defaultValue
  end
  --]]

  -- TODO: get rid of me
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

  -- update item tags
  local currentItemTags = configParameter("itemTags", {})

  if parameters.upgradeParameters then
    config.upgradeParameters = sb.jsonMerge(config.upgradeParameters or {}, parameters.upgradeParameters)
    if not set.new(currentItemTags)["upgradeableWeapon"] then
      table.insert(currentItemTags, "upgradeableWeapon")
    end
  end

  if not set.new(currentItemTags)["project45"] then
    table.insert(currentItemTags, "project45")
  end

  config.itemTags = currentItemTags


  -- generate seed if supposed to be seeded
  -- and seed is not established
  if not (parameters.noSeed or configParameter("seed", seed)) then
    -- seeded but no parameters.seed nor argued seed; so generate seed here
    parameters.seed = math.floor(math.random() * 2147483647)
  end

  -- configure seed
  local randStatBonus = parameters.randStatBonus or 0
  if configParameter("seed", seed) then
    parameters.seed = configParameter("seed", seed)
    -- sb.logInfo(string.format("Seed of %s: %d", config.itemName, parameters.seed))
    if parameters.seed == 69420 then
      randStatBonus = 1
    elseif parameters.seed == 42069 then
      randStatBonus = 0
    else
      local rng = sb.makeRandomSource(parameters.seed)
      randStatBonus = rng:randf(0, 1) * (parameters.bought and generalConfig.boughtRandBonusMult or 1)
    end

    if parameters.randStatBonus == nil then
      parameters.randStatBonus = randStatBonus
    end

    if parameters.randStatBonus ~= randStatBonus then
      parameters.requireRebuild = true
    end

  end

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end
  local currentLevel = configParameter("level", 1)

  construct(config, "project45GunModInfo")
  construct(parameters, "project45GunModInfo")
  
  -- calculate mod capacity
  local gunmodCapacity = 0
  local visualMods = set.new({"rail", "sights", "muzzle", "underbarrel", "stock"})
  for _, k in ipairs(deepConfigParameter({},"project45GunModInfo", "acceptsModSlot")) do
    if not visualMods[k] then
      gunmodCapacity = gunmodCapacity + 1
    end
  end
  local baseUpgradeCapacity = config.project45GunModInfo.upgradeCapacity
    or 10 + gunmodCapacity
      + (
          #deepConfigParameter({},"project45GunModInfo", "allowsConversion") +
          #deepConfigParameter({},"project45GunModInfo", "acceptsAmmoArchetype") > 0
          and 1 or 0
        )


  parameters.project45GunModInfo.upgradeCapacity = baseUpgradeCapacity + (currentLevel - 1)
  
  -- sb.logInfo(string.format("Generated %s", configParameter("itemName")))

  -- recalculate rarity
  local rarityLevel = currentLevel/10
  local levelRarityAssoc = {"common", "uncommon", "rare", "legendary", "essential"}
  local rarityLevelAssoc = {essential=1,legendary=0.8,rare=0.6,uncommon=0.4,common=0.2}
  if rarityLevelAssoc[string.lower(configParameter("rarity", "common"))] < rarityLevel then
    parameters.rarity = levelRarityAssoc[math.ceil(rarityLevel * #levelRarityAssoc)]
  end

  parameters.shortdescription = configParameter("shortdescription", "?")
  parameters.project45GunModInfo = configParameter("project45GunModInfo")

  if currentLevel >= 10 then
    parameters.shortdescription = config.shortdescription .. " ^yellow;^reset;"
  elseif currentLevel > 1 then
    local maxUpgradeLevel = root.assetJson("/interface/scripted/weaponupgrade/weaponupgradegui.config:upgradeLevel")
    local levelColor = currentLevel < maxUpgradeLevel and "^#96cbe7;" or "^yellow;"
    parameters.shortdescription = config.shortdescription .. string.format(" %sT%d^reset;", levelColor, currentLevel)
  end

  -- retrieve ability animation scripts
  local compiledAnimationScripts = {}
  local primaryAnimationScripts = setupAbility(config, parameters, "primary")
  local altAnimationScripts = setupAbility(config, parameters, "alt")
  local shiftAnimationScripts = setupAbility(config, parameters, "shift")
  -- alt <- shift <- primary <- config

  
  -- alt
  for i, animationScript in ipairs(altAnimationScripts) do
    if not project45util.isItemInList(compiledAnimationScripts, animationScript) then
      table.insert(compiledAnimationScripts, animationScript)
    end
  end

  --[[
  -- local shiftPrimaryAnimationScripts = setupAbility(config, parameters, "shiftPrimary")
  -- local shiftAltAnimationScripts = setupAbility(config, parameters, "shiftAlt")
  -- shiftPrimary
  for i, animationScript in ipairs(shiftPrimaryAnimationScripts) do
    if not project45util.isItemInList(compiledAnimationScripts, animationScript) then
      table.insert(compiledAnimationScripts, animationScript)
    end
  end

  -- shiftAlt
  for i, animationScript in ipairs(shiftAltAnimationScripts) do
    if not project45util.isItemInList(compiledAnimationScripts, animationScript) then
      table.insert(compiledAnimationScripts, animationScript)
    end
  end
  --]]

  -- shift
  for i, animationScript in ipairs(shiftAnimationScripts) do
    if not project45util.isItemInList(compiledAnimationScripts, animationScript) then
      table.insert(compiledAnimationScripts, animationScript)
    end
  end

  -- config
  for i, animationScript in ipairs(configParameter("animationScripts", {})) do
    if not project45util.isItemInList(compiledAnimationScripts, animationScript) then
      table.insert(compiledAnimationScripts, animationScript)
    end
  end

  -- primary
  for i, animationScript in ipairs(primaryAnimationScripts) do
    if not project45util.isItemInList(compiledAnimationScripts, animationScript) then
      table.insert(compiledAnimationScripts, animationScript)
    end
  end
  
  config.animationScripts = compiledAnimationScripts
  
  -- elemental type and config (for alt ability)
  local elementalType = configParameter("elementalType", "physical")
  replacePatternInData(config, nil, "<elementalType>", elementalType)
  if config.altAbility and config.altAbility.elementalConfig then
    util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType])
  end

  -- elemental type and config (for shift ability)
  local elementalType = configParameter("elementalType", "physical")

  replacePatternInData(config, nil, "<elementalType>", elementalType)
  if config.shiftAbility and config.shiftAbility.elementalConfig then
    util.mergeTable(config.shiftAbility, config.shiftAbility.elementalConfig[elementalType])
  end

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", currentLevel) * generalConfig.globalDamageMultiplier

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

    local hiddenParts = set.new(deepConfigParameter({nil}, "project45GunModInfo", "hiddenSlots"))
    
    for modSlot, _ in pairs(hiddenParts) do

      construct(parameters, "animationCustom", "animatedParts", "parts", modSlot, "properties")
      parameters.animationCustom.animatedParts.parts[modSlot].properties.image = ""

      construct(parameters, "animationCustom", "animatedParts", "parts", modSlot .. "Fullbright", "properties")
      parameters.animationCustom.animatedParts.parts[modSlot .. "Fullbright"].properties.image = ""

      -- needed to reconfigure muzzle offset
      parameters[modSlot .. "Offset"] = vec2.add(config[modSlot .. "Offset"] or {0, 0}, config.baseOffset or {0, 0})

    end

    local parts = {
      "middle",
      "charge",
      "magazine"
    }

    for _, part in ipairs(parts) do
      construct(config, "animationCustom", "animatedParts", "parts", part, "properties")
      config.animationCustom.animatedParts.parts[part].properties.offset = config.vanillaBaseOffset or config.baseOffset
      construct(config, "animationCustom", "animatedParts", "parts", part .. "Fullbright", "properties")
      config.animationCustom.animatedParts.parts[part .. "Fullbright"].properties.offset = config.vanillaBaseOffset or config.baseOffset
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
      if config[modPart .. "Offset"] and not hiddenParts[modPart] then
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

    -- VALUE VALIDATIONS: These validations serve to convert values to correct ones, if not already correct
    -- Validate primary ability fields
    parameters.primaryAbility.projectileCount = math.floor(primaryAbility("projectileCount"))
    parameters.primaryAbility.movementSpeedFactor = primaryAbility("movementSpeedFactor", 1)
    parameters.primaryAbility.jumpHeightFactor = primaryAbility("jumpHeightFactor", 1)
    parameters.primaryAbility.unjamAmount = primaryAbility("unjamAmount", 0.2)
    parameters.primaryAbility.unjamStDev = primaryAbility("unjamStDev" or 0.05)
    
    -- SETTING VALIDATIONS: These validations serve to reduce firing conditions and allow consistent logic.
    
    local semi = primaryAbility("semi")
    local manualFeed = primaryAbility("manualFeed")
    
    -- autoFireOnFullCharge only matters if the gun is semifire
    -- if an autofire gun is the kind that's charged, the charge is essentially it winding up.
    parameters.primaryAbility.autoFireOnFullCharge = (semi and primaryAbility("projectileKind") ~= "beam")
      and primaryAbility("autoFireOnFullCharge")
    
    -- self.fireBeforeOvercharge only matters if the gun is auto
    -- If this setting is false,
    -- then the gun only autofires at max charge, defeating the purpose of
    -- the overcharge providing bonus damage...
    -- Unless the gun continues firing until the gun is undercharged. (Should this be implemented?)
    parameters.primaryAbility.fireBeforeOvercharge = not semi
    parameters.primaryAbility.closeBoltOnEmpty = not manualFeed
      and primaryAbility("closeBoltOnEmpty")

    if primaryAbility("perfectChargeRange") then
      parameters.primaryAbility.perfectChargeDamageMult = math.max(
          primaryAbility("perfectChargeDamageMult", primaryAbility("chargeDamageMult")),
          primaryAbility("chargeDamageMult"),
          1
        )
    end
    
    -- self.resetChargeOnFire only matters if gun doesn't fire before overcharge
    -- otherwise, the gun will never overcharge
    -- If this is false and the gun is semifire, then the charge is maintained (while left click is held) and
    -- the gun can be quickly fired again after self.triggered is false
    parameters.primaryAbility.resetChargeOnFire = not primaryAbility("fireBeforeOvercharge")
      and primaryAbility("resetChargeOnFire")
    
    -- self.manualFeed only matters if the gun is semifire.
    -- Can you imagine an automatic bolt-action gun?
    parameters.primaryAbility.manualFeed = semi and manualFeed

    -- self.slamFire only matters if the gun is manual-fed (bolt-action)
    parameters.primaryAbility.slamFire = manualFeed and primaryAbility("slamFire")
    
    -- Let recoilMult affect recoilMaxDeg
    parameters.primaryAbility.recoilMaxDeg = primaryAbility("recoilMaxDeg") * primaryAbility("recoilMult")
    
    -- only load rounds through bolt if gun has internal mag
    parameters.primaryAbility.loadRoundsThroughBolt = primaryAbility("internalMag")
      and primaryAbility("loadRoundsThroughBolt")

    parameters.primaryAbility.bulletsPerReload = math.max(1, primaryAbility("bulletsPerReload"))
    parameters.primaryAbility.muzzleSmokeTime = primaryAbility("muzzleSmokeTime", 1.5)
    parameters.primaryAbility.burstCount = math.max(primaryAbility("burstCount"), 1)
  
    local cycleTime = primaryAbility("cycleTime", 0.1)
    if type(cycleTime) == "table" then
      cycleTime = math.min(cycleTime[1], cycleTime[2])
    end
    
    -- [[
    -- sync cycle animation
    local fireTimeRelatedStates = {
      "ejecting",
      "feeding"
    }
    
    local stateCycleTime = cycleTime / (#fireTimeRelatedStates + (primaryAbility("loopFiringAnimation", false) and 0 or 1))

    for _, state in ipairs(fireTimeRelatedStates) do
      construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", state)
      config.animationCustom.animatedParts.stateTypes.gun.states[state].cycle = stateCycleTime
      -- sb.logInfo(config.animationCustom.animatedParts.stateTypes.gun.states[state].cycle)
    end
    --]]
    
    --[[
    local stateCycleTime = cycleTime / (primaryAbility("loopFiringAnimation", false) and 3 or 2)
    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "ejecting")
    config.animationCustom.animatedParts.stateTypes.gun.states.ejecting.cycle = stateCycleTime
    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "feeding")
    config.animationCustom.animatedParts.stateTypes.gun.states.feeding.cycle = stateCycleTime
    --]]

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
  parameters.tooltipKind = "project45gun"

  parameters.tooltipFields = parameters.tooltipFields or {}
  if config.project45GunModInfo.uniqueType then
    parameters.tooltipFields.subtitle = generalTooltipConfig.categoryStringsX[config.project45GunModInfo.uniqueType][config.project45GunModInfo.category or "generic"]
  else
    parameters.tooltipFields.subtitle = generalTooltipConfig.categoryStrings[config.project45GunModInfo.category or "generic"] -- .. "^#D1D1D1;" .. config.gunArchetype or config.category
  end
  parameters.tooltipFields.levelLabel = util.round(currentLevel, 1)
  parameters.tooltipFields.rarityLabel = rarityConversions[configParameter("isUnique", false) and "unique" or string.lower(configParameter("rarity", "common"))]
  if elementalType ~= "physical" then
    parameters.tooltipFields.elementImage = "/interface/elements/"..elementalType..".png"
  end

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
    for i, modSlot in ipairs(mods) do
      if acceptedModSlots[modSlot] then
        parameters.tooltipFields[modSlot .. "Image"] = modList[modSlot] and modList[modSlot][3] or ""
        parameters.tooltipFields["itemDescription-" .. modSlot .. "Image"] = "/interface/itemdescriptions/project45gun/modslots/" .. modSlot .. ".png"
      else
        parameters.tooltipFields["itemDescription-" .. modSlot .. "Image"] = "/interface/itemdescriptions/project45gun/modslots/off-" .. modSlot .. ".png"
      end
    end
    
    if not (
      #(config.project45GunModInfo.allowsConversion or {}) == 0
      and #(config.project45GunModInfo.acceptsAmmoArchetype or {}) == 0
    )
    then
      parameters.tooltipFields.ammoTypeImage = modList.ammoType and modList.ammoType[3] or ""
      parameters.tooltipFields["itemDescription-ammoImage"] = "/interface/itemdescriptions/project45gun/modslots/ammo.png"
    else
      parameters.tooltipFields["itemDescription-ammoImage"] = "/interface/itemdescriptions/project45gun/modslots/off-ammo.png"
    end

  end
  
  if config.primaryAbility then
    
    local upgradeCapacity = deepConfigParameter(nil, "project45GunModInfo", "upgradeCapacity")
    if upgradeCapacity > -1 then
      local count = parameters.upgradeCount or 0
      local max = parameters.project45GunModInfo.upgradeCapacity
      parameters.tooltipFields.upgradeCapacityLabel = (count < max and "^#96cbe7;" or "^#777777;") .. (max - count) .. "/" .. max .. "^reset;"
      parameters.tooltipFields.itemDescriptionUpgradeCapLabel = project45util.colorText("#96cbe7", "U. Cap: " .. parameters.project45GunModInfo.upgradeCapacity)
    else
      parameters.tooltipFields.upgradeCapacityLabel = project45util.colorText("#96cbe7","Unlimited")
    end
    
    --[[
    
    chargeTime* = chargeTime
    If gun is auto, chargeTime* = 0

    If gun is manualFeed:
      fireTime* = cockTime (+ midCockDelay) + fireTime + chargeTime*
    else:
      fireTime* = cycleTime + fireTime + chargeTime*
    
    --]]
    
    local actualCycleTime = primaryAbility("manualFeed", false)
      and primaryAbility("midCockDelay", 0) + primaryAbility("cockTime", 0.1) / (primaryAbility("slamFire") and 2 or 1)
      or primaryAbility("cycleTime", 0.1)

    local chargeTime = primaryAbility("chargeTime", 0)
    
    if type(actualCycleTime) ~= "table" then
      actualCycleTime = {actualCycleTime, actualCycleTime}
    end

    if not primaryAbility("semi", true) then
      chargeTime = 0
    end
    
    local loFireTime = math.max(actualCycleTime[1], primaryAbility("fireTime", 0.1)) + chargeTime
    local hiFireTime = math.max(actualCycleTime[2], primaryAbility("fireTime", 0.1)) + chargeTime

    -- get DPS from gun archetype
    if config.gunArchetype and not config.overrideArchetypeDps then
      local archetypeDps = generalConfig.gunArchetypeDps[config.gunArchetype]
      config.primaryAbility.baseDps = (archetypeDps or config.primaryAbility.baseDamage)
    end

    -- convert DPS to Base Damage
    local baseDps = config.primaryAbility.baseDps
    if baseDps then
      
      -- AVERAGE FIRE TIME
      -- get midpoint of low and high firetime
      local dpsFiretime = math.max(loFireTime + hiFireTime / 2, generalConfig.minimumFireTime)
      if config.primaryAbility.semi then -- add average human seconds per click
        dpsFiretime = dpsFiretime + math.max(0.16, config.primaryAbility.fireTime)
      end
      if config.primaryAbility.manualFeed then -- add another average human seconds per click
        dpsFiretime = dpsFiretime + math.max(0.16, config.primaryAbility.fireTime)
      end
      if config.primaryAbility.burstCount > 1 then
        dpsFiretime = dpsFiretime / config.primaryAbility.burstCount
      end
      -- reloads after every shot
      --[[
      if config.primaryAbility.ammoPerShot >= config.primaryAbility.maxAmmo then
        dpsFiretime = dpsFiretime + config.primaryAbility.reloadTime/2 
      end
      --]]
      
      -- EXPECTED CRIT DAMAGE MULTIPLIER
      -- get crit stats
      local critChance = config.primaryAbility.critChance or 0
      local critDamage = config.primaryAbility.critDamageMult or 1

      -- calculate crit and non-crit damage (multiplier)
      local critTier = math.floor(critChance)
      local baseCritDamageMult = critTier > 0 and (critDamage + critTier - 1) or 0
      critDamage = math.max(1, baseCritDamageMult + (critTier > 0 and 1 or critDamage))
      local nCritDamage = math.max(1, baseCritDamageMult)
      
      -- restrict critChance within [0, 1]
      critChance = critChance - critTier
      local nCritChance = 1 - critChance

      -- calculate expected crit damage (multiplier)
      local expectedCritDamage = nCritChance * nCritDamage + critChance * critDamage

      -- AVERAGE CHARGE DAMAGE MULTIPLIER
      -- (exclude perfect charge damage)
      local averageChargeDamageMult = 1
      if config.primaryAbility.overchargeTime > 0 then
        averageChargeDamageMult = (
          (config.primaryAbility.chargeDamageMult or 1)
          + (config.primaryAbility.perfectChargeDamageMult or 1)
          + 1
        ) / 3
      end

      -- AVERAGE RELOAD RATING MULTIPLIER
      local reloadMultArr = config.primaryAbility.reloadRatingDamageMults or {1, 1, 1, 1}
      local reloadMult = 0
      for i=1, #reloadMultArr do
        reloadMult = reloadMult + reloadMultArr[i]
      end
      reloadMult = reloadMult / #reloadMultArr

      -- FINAL: BASE DAMAGE
      config.primaryAbility.baseDamage = baseDps * dpsFiretime / (reloadMult * expectedCritDamage * averageChargeDamageMult)

    end

    config.primaryAbility.baseDamage = (config.primaryAbility.baseDamage or 0) * primaryAbility("baseDamageMultiplier", 1)
    
    -- generate random stats
    -- Apply Random Stat Bonuses AFTER damage calculation
    -- these are _bonus_ stats, after all
    if randStatBonus > 0 and not configParameter("isRandomized") then
      parameters.primaryAbility.baseDamage = primaryAbility("baseDamage", 0) * (generalConfig.maxRandBonuses.baseDamage * randStatBonus + 1)
      parameters.primaryAbility.critChance = primaryAbility("critChance", 0) * (generalConfig.maxRandBonuses.critChance * randStatBonus + 1)
      parameters.primaryAbility.critDamageMult = primaryAbility("critDamageMult", 1) * (generalConfig.maxRandBonuses.critDamageMult * randStatBonus + 1)
      parameters.isRandomized = true
    end

    -- get charge-related numbers for calculation of displayed stat
    local overchargeTime = primaryAbility("overchargeTime", 0)
    local chargeDamageMult = primaryAbility("chargeDamageMult", 1)
    local perfectChargeDamageMult = math.max(
      primaryAbility("perfectChargeDamageMult", chargeDamageMult),
      chargeDamageMult,
      1
    )

    local baseDamage = primaryAbility("baseDamage", 0) * config.damageLevelMultiplier
    -- low damage = base damage * worst reload damage ( * chargeDamageMult if it's less than 1)
    local loDamage = baseDamage
      * math.min(table.unpack(primaryAbility("reloadRatingDamageMults", {0,0,0,0})))
      * ((overchargeTime > 0 and chargeDamageMult < 1) and chargeDamageMult or 1)
    
    -- high damage = base damage * best reload damage * overcharge mult
    local hiDamage = baseDamage
      * math.max(table.unpack(primaryAbility("reloadRatingDamageMults", {0,0,0,0})))
      * (overchargeTime > 0 and perfectChargeDamageMult or 1)


    parameters.tooltipFields.damagePerShotLabel = project45util.colorText("#FF9000", util.round(loDamage, 1) .. " - " .. util.round(hiDamage, 1))
    
    if primaryAbility("debug") then
      parameters.tooltipFields.damagePerShotLabel = project45util.colorText("#FF9000", primaryAbility("baseDamage", 0))
    end

    if loFireTime == hiFireTime then
      parameters.tooltipFields.fireTimeLabel = project45util.colorText("#FFD400", util.round(loFireTime*1000, 1) .. "ms")
    else
      parameters.tooltipFields.fireTimeLabel = project45util.colorText("#FFD400",
        util.round(loFireTime*1000, 1) .. " - " .. util.round(hiFireTime*1000, 1) .. "ms")
    end
    
    -- reload cost
    parameters.tooltipFields.reloadCostLabel = project45util.colorText("#b0ff78", util.round(primaryAbility("reloadCost", 0), 1))

    -- reload time
    local bulletReloadTime = primaryAbility("reloadTime", 0.1)
    local bulletsPerReload = primaryAbility("bulletsPerReload", 1)
    local maxAmmo = primaryAbility("maxAmmo")
    local actualReloadTime = bulletReloadTime * math.max(1, maxAmmo / bulletsPerReload)
    
    parameters.tooltipFields.reloadTimeLabel = util.round((actualReloadTime or 0), 1) .. "s"
    parameters.tooltipFields.reloadLabel = parameters.tooltipFields.reloadCostLabel .. " (" .. parameters.tooltipFields.reloadTimeLabel .. ")" 

    -- crit chance
    local critChance = primaryAbility("critChance", 0)
    if critChance > 0 then
      parameters.tooltipFields.critChanceLabel = project45util.colorText("#FF6767", util.round(critChance*100, 1) .. "%")
    else
      parameters.tooltipFields.critChanceLabel = project45util.colorText("#777777", util.round(critChance*100, 1) .. "%")
    end

    -- crit damage
    local critDamage = primaryAbility("critDamageMult", 1)
    local itemDescriptionCritDamage = ""
    if critChance > 0 then
      parameters.tooltipFields.critDamageLabel = project45util.colorText("#FF6767", util.round(critDamage, 1) .. "x")
      itemDescriptionCritDamage = project45util.colorText("#FF6767", " (" .. util.round(critDamage, 1) .. "x" .. ")")
    else
      parameters.tooltipFields.critDamageLabel = project45util.colorText("#777777", util.round(critDamage, 1) .. "x")
      itemDescriptionCritDamage = project45util.colorText("#777777", " (" .. util.round(critDamage, 1) .. "x" .. ")")

    end
    parameters.tooltipFields.critLabel = parameters.tooltipFields.critChanceLabel .. itemDescriptionCritDamage

    parameters.tooltipFields.bonusRatioLabel = ""
    parameters.tooltipFields.bonusRatioTitleLabel = ""
    parameters.tooltipFields.bonusRatioShadowLabel = ""
    if randStatBonus > 0 and parameters.isRandomized then
      local bonusDesc = parameters.randStatBonus == randStatBonus and string.format("^shadow;%d%%", math.floor(randStatBonus * 100)) or "^shadow;??%"
      local bonusColor = "#777777"
      if randStatBonus > 0.75 then
        bonusColor = "#fdd14d"
      elseif randStatBonus > 0.5 then
        bonusColor = "#d29ce7"
      elseif randStatBonus > 0.25 then
        bonusColor = "#60b8ea"
      end
      parameters.tooltipFields.bonusRatioLabel = project45util.colorText(bonusColor, bonusDesc)
      parameters.tooltipFields.bonusRatioTitleLabel = project45util.colorText(bonusColor, "^shadow;Stat Bonus")
      parameters.tooltipFields.bonusRatioShadowLabel = project45util.colorText("#a0a0a0", bonusDesc)
    end

    local descriptionScore = 0
    
    local passiveDesc = ""
    if primaryAbility("passiveDescription") then
      passiveDesc = primaryAbility("passiveDescription")
      descriptionScore = descriptionScore + math.ceil((#passiveDesc)/18)
      passiveDesc = project45util.colorText("#ffd495", passiveDesc) .. "\n"
    end

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
      chargeDesc = project45util.colorText("#FF5050", project45util.truncatef(primaryAbility("chargeTime", 0), 2) .. "s charge time.") .. "\n"
    end

    local overchargeDesc = ""
    if primaryAbility("overchargeTime", 0) > 0 and (chargeDamageMult ~= 1 or perfectChargeDamageMult ~= 1) then
      
      descriptionScore = descriptionScore + 1
      
      local chargeDamageDesc = chargeDamageMult ~= 1
        and project45util.colorText(
          chargeDamageMult > 1 and "#9dc6f5"
          or chargeDamageMult == 1 and "#A0A0A0"
          or "#FF5050",
          string.format("%.1fx", chargeDamageMult)
        )
        or ""
      
      local perfectChargeDamageDesc =
        (perfectChargeDamageMult ~= 1 and perfectChargeDamageMult ~= chargeDamageMult)
        and project45util.colorText(
          perfectChargeDamageMult > 1 and "#ffffa7"
          or "#FF5050",
          string.format(chargeDamageMult ~= 1 and " (%.1fx)" or "%.1fx", perfectChargeDamageMult)
        )
        or ""

      local descText = project45util.colorText(
          (chargeDamageMult > 1 or perfectChargeDamageMult > 1) and "#9dc6f5" or "#FF5050",
          chargeDamageMult ~= 1 and "Overcharge damage."
          or perfectChargeDamageMult ~= chargeDamageMult and "Perfect charge dmg."
        )

      overchargeDesc = project45util.colorText(
          (chargeDamageMult > 1 or perfectChargeDamageMult > 1) and "#9dc6f5" or "#FF5050",
          string.format("%s%s %s\n", chargeDamageDesc, perfectChargeDamageDesc, descText)
        )
    end

    local availableModSlots = deepConfigParameter({nil}, "project45GunModInfo", "acceptsModSlot")
    local availableExclude = set.new({"rail", "sights", "muzzle", "underbarrel", "stock"})
    local acceptsModDesc = ""
    for _, modSlot in ipairs(availableModSlots) do
      if not (modList[modSlot] or availableExclude[modSlot]) then
        acceptsModDesc = acceptsModDesc .. project45util.colorText(
          "#9da8af",
          string.format("No %s.\n", generalTooltipConfig.slotNames[modSlot] or modSlot)
        )
      end
    end
    
    local modListDesc = ""
    local exclude = set.new(generalTooltipConfig.techDisplayExcludedSlots or {})
    for modSlot, modKind in pairs(modList) do
      if not exclude[modSlot] and modKind[1] ~= "ability" then
        descriptionScore = descriptionScore + 1
        modListDesc = modListDesc .. project45util.colorText("#abfc6d", modKind[1]) .. "\n"
      end
    end

    local finalDescription = passiveDesc .. heavyDesc .. chargeDesc .. overchargeDesc .. multishotDesc .. acceptsModDesc .. modListDesc
    finalDescription = finalDescription == "" and project45util.colorText("#777777", "No notable qualities.") or finalDescription      
    parameters.tooltipFields.technicalLabel = finalDescription

    if config.lore then
      config.description = config.description .. " " .. project45util.colorText("#9da8af", config.lore)
    end

  end

  if parameters.altAbility then
    parameters.tooltipFields.altAbilityLabel = ("^#ffffa7;" .. (parameters.altAbility.name or "Unknown"))
  elseif config.altAbility then
    parameters.tooltipFields.altAbilityLabel = ("^#ffffa7;" .. (config.altAbility.name or "Unknown"))
  else
    parameters.tooltipFields.altAbilityLabel = "^#777777;None"
  end

  if parameters.shiftAbility then
    parameters.tooltipFields.shiftAbilityLabel = ("^#a8e6e2;" .. (parameters.shiftAbility.name or "Unknown"))
  elseif config.shiftAbility then
    parameters.tooltipFields.shiftAbilityLabel = ("^#a8e6e2;" .. (config.shiftAbility.name or "Unknown"))
  else
    parameters.tooltipFields.shiftAbilityLabel = "^#777777;None"
  end

  -- set price
  -- should this be handled elsewhere?
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", currentLevel)
  parameters.price = config.price + (parameters.moddedPrice or 0) -- needed for gunshop

  return config, parameters
end