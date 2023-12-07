require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/project45abilities.lua"

function build(directory, config, parameters, level, seed)
  
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

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end

  parameters.shortdescription = config.shortdescription
  parameters.project45GunModInfo = config.project45GunModInfo

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
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

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
    local cycleTime = config.primaryAbility.cycleTime
    if type(cycleTime) == "table" then
      cycleTime = math.min(cycleTime[1], cycleTime[2])
    end
    local stateCycleTime = cycleTime / (#fireTimeRelatedStates + (config.primaryAbility.loopFiringAnimation and 0 or 1))
    for _, state in ipairs(fireTimeRelatedStates) do
      construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", state)
      config.animationCustom.animatedParts.stateTypes.gun.states[state].cycle = stateCycleTime
      -- sb.logInfo(config.animationCustom.animatedParts.stateTypes.gun.states[state].cycle)
    end

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "firing")
    config.animationCustom.animatedParts.stateTypes.gun.states.firing.cycle = config.primaryAbility.loopFiringAnimation and cycleTime or stateCycleTime

    construct(config, "animationCustom", "animatedParts", "stateTypes", "charge", "states", "charging")
    config.animationCustom.animatedParts.stateTypes.charge.states.charging.cycle = math.max(0.05, cycleTime)

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "boltPulling")
    config.animationCustom.animatedParts.stateTypes.gun.states.boltPulling.cycle = config.primaryAbility.cockTime/2

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "unjamming")
    config.animationCustom.animatedParts.stateTypes.gun.states.unjamming.cycle = config.primaryAbility.cockTime/2

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "boltPushing")
    config.animationCustom.animatedParts.stateTypes.gun.states.boltPushing.cycle = config.primaryAbility.cockTime/2

  end

  -- tooltip
  -- populate tooltip fields
  if config.tooltipKind == "project45gun" then
    config.tooltipFields = config.tooltipFields or {}
    config.tooltipFields.subtitle = "^#FFFFFF;" .. config.gunArchetype or config.category
    -- config.tooltipFields.title = "^FF0000;FUCK"  -- doesn't work
    -- config.tooltipFields.subTitle = "^#FFFFFF;BASE"  -- works
    -- config.tooltipFields.subTitle.color = {255,255,255} -- doesn't work
    config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
    
    -- IMPORT PARAMETERS
    --[[
    if parameters.primaryAbility then
        config.primaryAbility = sb.jsonMerge(config.primaryAbility, parameters.primaryAbility)
    end
    --]]

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
    

    if elementalType ~= "physical" then
      config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
    end

    if config.primaryAbility then
      
      if config.project45GunModInfo and config.project45GunModInfo.statModCountMax
      then
        if config.project45GunModInfo.statModCountMax > -1 then
          local count = parameters.statModCount or 0
          local max = config.project45GunModInfo.statModCountMax
          config.tooltipFields.upgradeCapacityLabel = (count < max and "^#96cbe7;" or "^#777777;") .. (max - count) .. "/" .. max .. "^reset;"
        else
          config.tooltipFields.upgradeCapacityLabel = "^#96cbe7;Unlimited^reset;"
        end
      else
        config.tooltipFields.upgradeCapacityLabel = "^#777777;0/0^reset;"
      end

        
      -- damage per shot
      -- FIXME: max damage seems inaccurate
      config.primaryAbility.baseDamage = parameters.primaryAbility.baseDamage or config.primaryAbility.baseDamage
      config.primaryAbility.reloadRatingDamageMults = parameters.primaryAbility.reloadRatingDamageMults or config.primaryAbility.reloadRatingDamageMults
      local baseDamage = (config.primaryAbility.baseDamage or 0)
      * config.damageLevelMultiplier
      -- low damage = base damage * worst reload damage
      local loDamage = baseDamage
        * math.min(table.unpack(config.primaryAbility.reloadRatingDamageMults))
      -- high damage = base damage * best reload damage * last shot damage mult * overcharge mult
      local hiDamage = baseDamage
        * math.max(table.unpack(config.primaryAbility.reloadRatingDamageMults))
        * config.primaryAbility.lastShotDamageMult
        * (config.primaryAbility.overchargeTime > 0 and 2 or 1)
      config.tooltipFields.damagePerShotLabel = "^#FF9000;" .. util.round(loDamage, 1) .. " - " .. util.round(hiDamage, 1)

      -- fire rate
      config.primaryAbility.manualFeed = parameters.primaryAbility.manualFeed or config.primaryAbility.manualFeed
      config.primaryAbility.cockTime = parameters.primaryAbility.cockTime or config.primaryAbility.cockTime
      config.primaryAbility.cycleTime = parameters.primaryAbility.cycleTime or config.primaryAbility.cycleTime
      
      local actualCycleTime = config.primaryAbility.manualFeed
        and config.primaryAbility.cockTime
        or config.primaryAbility.cycleTime
      
      if type(actualCycleTime) ~= "table" then
        actualCycleTime = {actualCycleTime, actualCycleTime}
      end
      
      local loFireRate = actualCycleTime[1] + (parameters.primaryAbility.fireTime or config.primaryAbility.fireTime)
      local hiFireRate = actualCycleTime[2] + (parameters.primaryAbility.fireTime or config.primaryAbility.fireTime)
      config.tooltipFields.fireRateLabel = ("^#FFD400;" .. util.round(loFireRate*1000, 1))
      .. (loFireRate == hiFireRate and "ms" or (" - " .. util.round(hiFireRate*1000, 1) .. "ms"))
      
      -- set reload cost
      config.primaryAbility.reloadCost = parameters.primaryAbility.reloadCost or config.primaryAbility.reloadCost
      config.tooltipFields.reloadCostLabel = "^#b0ff78;" .. config.primaryAbility.reloadCost or 0

      local bulletReloadTime = parameters.primaryAbility.reloadTime or config.primaryAbility.reloadTime
      local bulletsPerReload = parameters.primaryAbility.bulletsPerReload or config.primaryAbility.bulletsPerReload
      local maxAmmo = parameters.primaryAbility.maxAmmo or config.primaryAbility.maxAmmo
      local actualReloadTime = bulletReloadTime * math.max(1, maxAmmo / bulletsPerReload)
      config.primaryAbility.reloadTime = bulletReloadTime
      config.tooltipFields.reloadTimeLabel = util.round(
        (actualReloadTime or 0),
        1
      ) .. "s"

      config.primaryAbility.critChance = parameters.primaryAbility.critChance or config.primaryAbility.critChance
      config.tooltipFields.critChanceLabel = (config.primaryAbility.critChance > 0 and "^#FF6767;" or "^#777777;") .. util.round(
        (config.primaryAbility.critChance or 0) * 100,
        1
      ) .. "%"

      config.primaryAbility.critDamageMult = parameters.primaryAbility.critDamageMult or config.primaryAbility.critDamageMult
      config.tooltipFields.critDamageLabel = (config.primaryAbility.critChance > 0 and "^#FF6767;" or "^#777777;") .. util.round(
        (config.primaryAbility.critDamageMult or 1),
        1
      ) .. "x"

      config.primaryAbility.heavyWeapon = parameters.primaryAbility.heavyWeapon or config.primaryAbility.heavyWeapon
      local heavyDesc = config.primaryAbility.heavyWeapon and "^#FF5050;Heavy.^reset;\n" or ""

      config.primaryAbility.multishot = parameters.primaryAbility.multishot or config.primaryAbility.multishot
      local multishotDesc = config.primaryAbility.multishot ~= 1 and ("^#9dc6f5;" .. util.round(config.primaryAbility.multishot, 1) .. "x multishot.^reset;\n") or ""
      
      config.primaryAbility.chargeTime = parameters.primaryAbility.chargeTime or config.primaryAbility.chargeTime
      local chargeDesc = config.primaryAbility.chargeTime > 0 and ("^#FF5050;" .. util.round(config.primaryAbility.chargeTime, 1) .. "s charge time.^reset;\n") or ""
      
      config.primaryAbility.overchargeTime = parameters.primaryAbility.overchargeTime or config.primaryAbility.overchargeTime
      local overchargeDesc = config.primaryAbility.overchargeTime > 0 and ("^#9dc6f5;" .. util.round(config.primaryAbility.overchargeTime, 1) .. "s overcharge.^reset;\n") or ""
      

      local modListDesc = ""
      if modList then
        modListDesc = "^#abfc6d;"
        -- FIXME: Turn me to a set
        local exclude = set.new({"ability","rail","sights","muzzle","underbarrel","stock","ammoType"})
        for modSlot, modKind in pairs(modList) do
          if not exclude[modSlot] and modKind[1] ~= "ability" then
            modListDesc = modListDesc .. modKind[1] .. ".\n"
          end
        end
        modListDesc = modListDesc .. "^reset;"
      end

      local finalDescription = heavyDesc .. chargeDesc .. overchargeDesc .. multishotDesc .. modListDesc -- .. config.description
      config.description = finalDescription -- == "" and "^#777777;No notable qualities.^reset;" or finalDescription

    end
    -- sb.logInfo("[ PROJECT 45 ] " .. sb.printJson(parameters.primaryAbility))
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

function rgbToHex(rgbArray)
  local hexString = string.format("%02X%02X%02X", rgbArray[1], rgbArray[2], rgbArray[3])
  return hexString
end