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
    config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
    config.tooltipFields.dpsLabel = util.round((config.primaryAbility.baseDps or 0) * config.damageLevelMultiplier, 1)
    config.tooltipFields.speedLabel = util.round(1 / (config.primaryAbility.fireTime or 1.0), 1)
    config.tooltipFields.damagePerShotLabel = util.round((config.primaryAbility.baseDps or 0) * (config.primaryAbility.fireTime or 1.0) * config.damageLevelMultiplier, 1)
    config.tooltipFields.energyPerShotLabel = util.round((config.primaryAbility.energyUsage or 0) * (config.primaryAbility.fireTime or 1.0), 1)
    if elementalType ~= "physical" then
      config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
    end
    if config.primaryAbility then
      config.tooltipFields.primaryAbilityTitleLabel = "Primary:"
      config.tooltipFields.primaryAbilityLabel = config.primaryAbility.name or "unknown"
    end
    if config.altAbility then
      config.tooltipFields.altAbilityTitleLabel = "Special:"
      config.tooltipFields.altAbilityLabel = config.altAbility.name or "unknown"
    end
  end

  -- set price
  -- TODO: should this be handled elsewhere?
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end
