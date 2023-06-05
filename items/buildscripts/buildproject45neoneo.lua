require "/scripts/util.lua"
require "/scripts/vec2.lua"
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

  construct(config, "animationParts", "muzzleFlash")
  config.animationParts.muzzleFlash = "/items/active/weapons/ranged/project45-muzzleflash.png"

  -- gun offsets
  if config.baseOffset then

    local parts = {
      "middle"
    }

    for _, part in ipairs(parts) do
      construct(config, "animationCustom", "animatedParts", "parts", part, "properties")
      config.animationCustom.animatedParts.parts[part].properties.offset = config.baseOffset
      construct(config, "animationCustom", "animatedParts", "parts", part .. "Fullbright", "properties")
      config.animationCustom.animatedParts.parts[part .. "Fullbright"].properties.offset = config.baseOffset
    end
    
    if config.muzzleOffset then
      config.muzzleOffset = vec2.add(config.muzzleOffset, config.baseOffset)
    end

  end

  if config.primaryAbility then

    -- sync cycle animation
    local fireTimeRelatedStates = {
      "firing",
      "ejecting",
      "feeding"
    }
    local stateCycleTime = config.primaryAbility.cycleTime / #fireTimeRelatedStates
    for _, state in ipairs(fireTimeRelatedStates) do
      construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", state)
      config.animationCustom.animatedParts.stateTypes.gun.states[state].cycle = stateCycleTime
      -- sb.logInfo(config.animationCustom.animatedParts.stateTypes.gun.states[state].cycle)
    end

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "boltPulling")
    config.animationCustom.animatedParts.stateTypes.gun.states.boltPulling.cycle = config.primaryAbility.cockTime/2

    construct(config, "animationCustom", "animatedParts", "stateTypes", "gun", "states", "boltPushing")
    config.animationCustom.animatedParts.stateTypes.gun.states.boltPushing.cycle = config.primaryAbility.cockTime/2

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