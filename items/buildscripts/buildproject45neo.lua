require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/project45abilities.lua"

function build(directory, config, parameters, level, seed)
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

  -- retrieve ability animation scripts
  local primaryAnimationScripts = setupAbility(config, parameters, "primary")
  local altAnimationScripts = setupAbility(config, parameters, "alt")

  -- push primary animation scripts
  -- to altAnimationScripts
  for i, animationScript in ipairs(primaryAnimationScripts) do
    table.insert(altAnimationScripts, animationScript)
  end

  -- let the item's animationScripts be altAnimationScripts
  config.animationScripts = {}
  util.mergeTable(config.animationScripts, altAnimationScripts or {})

  -- sb.logInfo("[PROJECT 45] (buildproject45neo.lua) config.animationScripts = " .. sb.printJson(config.animationScripts))
  
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

  -- gun offsets
  if config.baseOffset then
    
    -- middle
    construct(config, "animationCustom", "animatedParts", "parts", "middle", "properties")
    config.animationCustom.animatedParts.parts.middle.properties.offset = config.baseOffset
  
    -- fullbright parts
    construct(config, "animationCustom", "animatedParts", "parts", "middleFullbright", "properties")
    config.animationCustom.animatedParts.parts.middleFullbright.properties.offset = config.baseOffset

    -- magazine parts
    construct(config, "animationCustom", "animatedParts", "parts", "mag", "properties")
    config.animationCustom.animatedParts.parts.mag.properties.offset = config.baseOffset

    -- fullbright parts
    construct(config, "animationCustom", "animatedParts", "parts", "magFullbright", "properties")
    config.animationCustom.animatedParts.parts.magFullbright.properties.offset = config.baseOffset
    
    
    if config.muzzleOffset then
      config.muzzleOffset = vec2.add(config.muzzleOffset, config.baseOffset)
    end

    if config.ejectionPortOffset then
      config.ejectionPortOffset = vec2.add(config.ejectionPortOffset, config.baseOffset)
    end

    if config.magazineOffset then
      config.magazineOffset = vec2.add(config.magazineOffset, config.baseOffset)
    end

  end

  -- populate tooltip fields
  if config.tooltipKind ~= "base" then
    config.tooltipFields = {}
    -- config.tooltipFields.title = "^FF0000;FUCK"  -- doesn't work
    -- config.tooltipFields.subTitle = "^#FFFFFF;BASE"  -- works
    -- config.tooltipFields.subTitle.color = {255,255,255} -- doesn't work
    config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)

    -- damage
    local loDamage = (config.primaryAbility.baseDamage or 0) * config.damageLevelMultiplier
    -- perfect reload * last shot damage mult * overcharge mult
    local hiDamage = loDamage * 1.3 * config.primaryAbility.lastShotDamageMult * (config.primaryAbility.overchargeTime > 0 and 2 or 1)
    config.tooltipFields.damagePerShotLabel = "^#FF9000;" .. util.round(loDamage, 1) .. " - " .. util.round(hiDamage, 1)

    -- fire rate
    if type(config.primaryAbility.cycleTime) ~= "table" then
      config.primaryAbility.cycleTime = {config.primaryAbility.cycleTime, config.primaryAbility.cycleTime}
    end
    local loFireRate = config.primaryAbility.cycleTime[1] + config.primaryAbility.fireTime
    local hiFireRate = config.primaryAbility.cycleTime[2] + config.primaryAbility.fireTime
    config.tooltipFields.fireRateLabel = ("^#FFD400;" .. util.round(loFireRate, 1))
    .. (loFireRate == hiFireRate and "s" or (" - " .. util.round(hiFireRate, 1) .. "s"))

    config.tooltipFields.reloadCostLabel = "^#b0ff78;" .. util.round(
      (config.primaryAbility.reloadCost or 0) * 100,
      1
    ) .. "%"

    config.tooltipFields.reloadTimeLabel = util.round(
      (config.primaryAbility.reloadTime or 0),
      1
    ) .. "s"

    if elementalType ~= "physical" then
      config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
    end

    if config.primaryAbility then

      config.tooltipFields.critChanceLabel = (config.primaryAbility.critChance > 0 and "^#FF6767;" or "^#777777;") .. util.round(
        (config.primaryAbility.critChance or 0) * 100,
        1
      ) .. "%"

      config.tooltipFields.critDamageLabel = (config.primaryAbility.critChance > 0 and "^#FF6767;" or "^#777777;") .. util.round(
        (config.primaryAbility.critDamageMult or 1),
        1
      ) .. "x"

      local heavyDesc = config.primaryAbility.heavyWeapon and "^#FF5050;Heavy.^reset; " or ""
      local multishotDesc = config.primaryAbility.multishot ~= 1 and (
        "^#9dc6f5;".. util.round(
          (config.primaryAbility.multishot - math.floor(config.primaryAbility.multishot)) * 100, 1) .. 
          "% chance to shoot " .. math.ceil(config.primaryAbility.multishot) .. "x the amount of bullets.^reset; ") or ""
      local chargeDesc = config.primaryAbility.chargeTime > 0 and ("^#FF5050;" .. util.round(config.primaryAbility.chargeTime, 1) .. "s charge time.^reset; ") or ""
      local overchargeDesc = config.primaryAbility.overchargeTime > 0 and ("^#9dc6f5;" .. util.round(config.primaryAbility.overchargeTime, 1) .. "s overcharge.^reset; ") or ""
      
      config.description = heavyDesc .. chargeDesc .. overchargeDesc .. multishotDesc .. config.description

    end
    
    --[[
    -- mods
    local mods = {}
    if config.altAbility then table.insert(mods, config.altAbility.name) end
    if config.primaryAbility.dashParams.enabled then table.insert(mods, "Dash") end
    if config.primaryAbility.laser.enabled then table.insert(mods, "Laser") end
    local modLabel = ""
    for i=1,#mods,1 do
      if mods[i] then
        modLabel = modLabel .. mods[i]
        if i < #mods then modLabel = modLabel .. ", " end
      end
    end
  
    config.tooltipFields.altAbilityLabel = modLabel ~= "" and ("^#ABD2FF;" .. modLabel) or "^#777777;None"
    --]]

    config.tooltipFields.altAbilityLabel = config.altAbility and ("^#ABD2FF;" .. (config.altAbility.name or "unknown")) or "^#777777;None"

  end

  -- set price
  -- TODO: should this be handled elsewhere?
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end
