require "/scripts/project45/project45util.lua"
require "/scripts/versioningutils.lua"
require "/scripts/util.lua"
require "/scripts/set.lua"

function build(directory, config, parameters, level, seed)

  parameters = parameters or {}
  config.tooltipFields = config.tooltipFields or {}

  local extrinsicModSlots = set.new({
    "rail",
    "sights",
    "muzzle",
    "underbarrel",
    "stock"
  })

  local statSlots = {
    baseDamage = "^#FF9000;Base Damage",
    fireTime = "^#FFD400;Fire Time",
    reloadCost = "^#b0ff78;Reload Cost",
    critChance = "^#FF6767;Crit Chance",
    critDamage = "^#FF6767;Crit Damage",
    multiple = "^#A8E6E2;Multiple",
    level = "^#a8e6e2;Level"
  }

  --[[
  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end
  --]]

  construct(config, "augment")

  local wildcardStatInfo = nil


  if config.category == "Stat Mod"
  and config.augment.wildcard
  and (parameters.seed or seed) then
    parameters.seed = parameters.seed or seed
    local rng = sb.makeRandomSource(parameters.seed)
    local statNames = {
      "baseDamage",
      "reloadCost",
      "critChance",
      "critDamage"
    }
    local maxStats = {
      baseDamage = {
        additive = 10,
        multiplicative = 0.5
      },
      reloadCost = {
        additive = 3,
        multiplicative = 0.5
      },
      critChance = {
        additive = 0.25,
        multiplicative = 1
      },
      critDamage = {
        additive = 0.75,
        multiplicative = 0.25
      },
    }
    local percent = set.new({
      "critChance"
    })
    local isdiv = set.new({
      "reloadCost",
    })
    wildcardStatInfo = ""
    -- util.round(x, 1)
    config.archetype = nil
    config.slot = nil
    local firstStat = (rng:randu32() % #statNames) + 1
    local statsModified = 0
    for i, statName in ipairs(statNames) do
      if rng:randb() or i == firstStat then
        statsModified = statsModified + 1
        config.augment[statName] = {}
        local modification = rng:randb() and "additive" or "multiplicative"
        local actualStat = rng:randf(0, maxStats[statName][modification]) * (isdiv[statName] and modification == "additive" and -1 or 1)
        config.augment[statName][modification] = actualStat

        config.slot = statsModified == 1 and statName or "multiple"
        
        if config.archetype then
          config.archetype = config.archetype ~= modification and "Mixed" or modification
        else
          config.archetype = modification
        end

        wildcardStatInfo = wildcardStatInfo .. string.format("%s %s%.1f%s^reset;\n",
          statSlots[statName],
          isdiv[statName] and modification == "additive" and "" or "+",
          util.round(actualStat * (percent[statName] and modification == "additive" and 100 or 1), 1),
          (modification == "multiplicative" and (isdiv[statName] and "d" or "x") or (percent[statName] and "%" or ""))
        )
      end
    end
    config.archetype = project45util.capitalize(config.archetype)
  end

  -- if no set upgrade cost,
  -- extrinsic mods are free,
  -- intrinsic mods cost 1 upgrade capacity
  if not config.augment.upgradeCost then
    config.augment.upgradeCost = extrinsicModSlots[config.augment.slot or config.slot] and 0 or 1
  end

  config.tooltipFields.categoryLabel = project45util.categoryStrings[config.augment.category or "universal"]

  if config.category == "Ammo Mod" or config.category == "Converter Mod" then
    config.tooltipFields.slotLabel = "^#9da8af;Ammo"
  
  elseif config.category == "Stat Mod" then
    config.tooltipFields.slotTitleLabel = "Stat"
    config.tooltipFields.slotLabel = statSlots[config.slot]
  
  else
    config.tooltipFields.slotLabel = "^#9da8af;" ..
      project45util.capitalize(config.augment.slot or config.slot or "N/A")
  
  end

  config.tooltipFields.archetypeLabel = ""
  if config.category == "Gun Mod" then
    config.tooltipFields.archetypeTitleLabel = "Mod Type"
    if not config.archetype then
      if extrinsicModSlots[config.augment.slot or config.slot] then
        config.tooltipFields.archetypeLabel = "^#ea9931;Extrinsic"
      else
        config.tooltipFields.archetypeLabel = "^#ea9931;Intrinsic"  
      end
    end    
  elseif config.category == "Ammo Mod" then
      config.tooltipFields.archetypeTitleLabel = "Ammo Archetype"
      config.tooltipFields.archetypeLabel = "^#ea9931;" .. project45util.capitalize(config.augment.archetype)
  
  else
    if config.category == "Ability Mod" then
      config.tooltipFields.archetypeTitleLabel = "Ability Type"
    elseif config.category == "Stat Mod" then
      config.tooltipFields.archetypeTitleLabel = "Application"
    end
    config.tooltipFields.archetypeLabel = "^#ea9931;" .. (
      project45util.capitalize(config.augment.archetype)
      or config.archetype
      or "^#a0a0a0;N/A"
    )
  end

  config.tooltipFields.technicalLabel = project45util.colorText("#777777", string.format("Upgrade Cost: %d\n", config.augment.upgradeCost))

  if config.technicalInfo then
    config.tooltipFields.technicalLabel = config.tooltipFields.technicalLabel .. "^#ffd495;" .. config.technicalInfo .. "^reset;\n"
  end
  if config.statInfo then
    config.tooltipFields.technicalLabel = config.tooltipFields.technicalLabel .. "^#b2e89d;" .. (wildcardStatInfo or config.statInfo) .. "^reset;\n"
  end

  return config, parameters
end