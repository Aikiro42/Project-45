require "/scripts/project45/project45util.lua"
require "/scripts/versioningutils.lua"
require "/scripts/util.lua"
require "/scripts/set.lua"

function build(directory, config, parameters, level, seed)

  parameters = parameters or {}
  config.tooltipFields = config.tooltipFields or {}

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

  local extrinsicModSlots = set.new({
    "rail",
    "sights",
    "muzzle",
    "underbarrel",
    "stock"
  })

  local rarityConversions = {
    common = project45util.colorText("#96cbe7", "R (Common)"),
    uncommon = project45util.colorText("#96cbe7", "R (Uncommon)"),
    rare = project45util.colorText("#d29ce7", "SR (Rare)"),
    legendary = project45util.colorText("#d29ce7", "SR (Legendary)"),
    essential = project45util.colorText("#ffffa7", "SSR (Essential)"),
    unique = project45util.colorText("#f4988c", "XSSR (UNIQUE)")
  }

  local statSlots = {
    baseDamage = "^#FF9000;Base Damage",
    fireTime = "^#FFD400;Fire Time",
    reloadCost = "^#b0ff78;Reload Cost",
    critChance = "^#FF6767;Crit Chance",
    critDamage = "^#FF6767;Crit Damage",
    multiple = "^#A8E6E2;Multiple",
    level = "^#a8e6e2;Level"
  }

  local generalModConfig = root.assetJson("/configs/project45/project45_generalmod.config", {})
  local generalTooltipConfig = root.assetJson("/configs/project45/project45_generaltooltip.config", {})
  local generalStatConfig = root.assetJson("/configs/project45/project45_generalstat.config", {})

  -- Formats a stat and modifier value to be displayed in the tooltip.
  -- @param stat: string
  -- @param op: string
  -- @param val: number
  -- @param override: causes the function to set formattedVal to be exactly val,
  --  used if val can possibly be a string
  -- @return formattedStat: string, formattedVal: string
  local formatStat = function(stat, op, val, override)
    --[[
    config.tooltipFields["stat" .. stats .. "TitleLabel"] = "^#d29ce7;???"
    config.tooltipFields["stat" .. stats .. "Label"] = "^#d29ce7;???"
    stats = stats + 1
    --]]
    
    -- values to be changed and returned
    local formattedStat = stat
    local statColor = generalStatConfig.statColors.default

    local formattedVal
    if override then
      formattedVal = project45util.colorText(statColor, string.format("%s", val))
    else
      formattedVal = type(val) ~= "table" and string.format("%.1f", val) or "^#d29ce7;???"
    end

    local statGroup = generalStatConfig.statGroupAssignments
    local isMember = statGroup
    local isGroup = set.new(generalStatConfig.statGroups)
    
    -- format stat
    local statName = project45util.capitalize(stat)
    if not isMember[stat] and not isGroup[stat] then -- individual stat
      statColor = generalStatConfig.statColors[stat] or statColor
      statName = generalStatConfig.statNames[stat] or statName
    
    else -- member/group stat
      local group = statGroup[stat] or stat
      statColor = generalStatConfig.statColors[stat] or generalStatConfig.groupColors[group] or statColor

      statName = generalStatConfig.statNames[stat] or generalStatConfig.groupNames[group] or statName
    
    end
    formattedStat = project45util.colorText(type(val) == "table" and "#d29ce7" or statColor, statName)

    if override then
      return formattedStat, formattedVal
    end

    -- format mod val
    if type(val) ~= "table" then
      if op == "additive" or op == "rebase" then
        local isIntegerStat = set.new(generalStatConfig.integerStats or {})
        local statFormat
        if not isGroup[stat] then
          statFormat = (generalStatConfig.statFormats or {})[stat] or {'', 1, 1, ''}
        else
          statFormat = (generalStatConfig.groupFormats or {})[stat] or {'', 1, 1, ''}
        end

        local prefix = statFormat[1]
        local mult = statFormat[2]
        local round = statFormat[3]
        local suffix = statFormat[4]
        
        formattedVal = string.format("%s%s%s%s",
          op == "rebase" and '=' or (val > 0 and '+' or ''),
          prefix,
          isIntegerStat[stat] and "" .. math.ceil(val * mult) or string.format("%.".. round .."f", val * mult),
          suffix
        )
      else
        local isBad
        if not isGroup[stat] then
          isBad = set.new(generalStatConfig.badStats or {})[stat]
        else
          isBad = set.new(generalStatConfig.badGroups or {})[stat]
        end

        formattedVal = string.format("%s%.1f%s",
          op == "rebaseMult" and 'x' or (val > 0 and '+' or ''),
          val,
          op == "multiplicative" and (isBad and 'd' or 'x') or '')
      end
      formattedVal = project45util.colorText(statColor, formattedVal)
    end

    return formattedStat, formattedVal
  end

  construct(config, "augment")  -- make sure config.augment exists
  construct(config, "tooltipFields")  -- make sure config.tooltipFields exists
  
  -- if no set upgrade cost,
  -- extrinsic mods are free,
  -- intrinsic mods cost 1 upgrade capacity
  if not deepConfigParameter(nil, "augment", "cost") then
    config.augment.cost = extrinsicModSlots[deepConfigParameter(configParameter("slot"), "augment", "slot")] and 0 or 1
  end

  -- Change category label
  config.tooltipFields.categoryLabel = generalTooltipConfig.categoryStrings[deepConfigParameter("universal", "augment", "category")] or ""

  -- Change slot label
  config.tooltipFields.slotLabel = project45util.capitalize(deepConfigParameter(nil, "augment", "slot"))
  if not config.tooltipFields.slotLabel then
    -- Stat < Passive < Ammo/Conversion < Ability < Unknown/Intrinsic
    config.tooltipFields.slotLabel = "^#7e7e7e;???"
    if deepConfigParameter(nil, "augment", "ability") then
      config.tooltipFields.slotLabel = "Ability"
    elseif deepConfigParameter(deepConfigParameter(nil, "augment", "conversion"), "augment", "ammo") then
      config.tooltipFields.slotLabel = "Ammo"
    elseif deepConfigParameter(nil, "augment", "passive") then
      config.tooltipFields.slotLabel = "Passive"
    elseif deepConfigParameter(nil, "augment", "stat") then
      config.tooltipFields.slotLabel = "Stats"
    end
  end
  config.tooltipFields.slotLabel = project45util.colorText("#9da8af", config.tooltipFields.slotLabel)

  -- Change archetype and subtitle
  local modCategory = configParameter("modCategory")
  if modCategory then
    if modCategory == "abilityMod" then
      config.tooltipFields.subtitle = "Ability Mod"
      config.tooltipFields.archetypeTitleLabel = "Ability Type"
      local isActive = deepConfigParameter(false, "augment", "ability", "overrideTwoHanded")
      local shift = deepConfigParameter(false, "augment", "ability", "hasShiftAction")
      if isActive then
        config.tooltipFields.archetypeLabel = "Active"
      elseif shift then
        config.tooltipFields.archetypeLabel = "Shift"
      else
        config.tooltipFields.archetypeLabel = "Passive"
      end

    elseif modCategory == "gunMod" then
      config.tooltipFields.subtitle = "Gun Mod"
      config.tooltipFields.archetypeTitleLabel = "Type"
      local isExtrinsic = set.new({"rail", "sights", "muzzle", "underbarrel", "stock"})[deepConfigParameter("???", "augment", "slot")]
      config.tooltipFields.archetypeLabel = isExtrinsic and "Extrinsic" or "Intrinsic"


    elseif modCategory == "ammoMod" or modCategory == "converterMod" then
      config.tooltipFields.subtitle = "Ammo Mod"
      config.tooltipFields.archetypeTitleLabel = "Archetype"
      local archetype = deepConfigParameter(nil, "augment", "ammo", "archetype")
      config.tooltipFields.archetypeLabel = generalModConfig.archetypeNames[archetype] or project45util.capitalize(archetype) or "Conversion"

    elseif modCategory == "statMod" then
      config.tooltipFields.subtitle = "Stat Mod"
      config.tooltipFields.archetypeTitleLabel = "Stat Type"
      local random = deepConfigParameter(nil, "augment", "stat", "randomStatParams")
      config.tooltipFields.archetypeLabel = random and "Random" or "Static"

    elseif modCategory == "passiveMod" then
      config.tooltipFields.subtitle = "Passive Mod"
      config.tooltipFields.archetypeTitleLabel = "Passive Type"
      local isActive = deepConfigParameter(false, "augment", "passive", "overrideShiftAction")
      config.tooltipFields.archetypeLabel = isActive and "Active" or "Passive"

    else
      config.tooltipFields.subtitle = "Generic Mod"
      config.tooltipFields.archetypeTitleLabel = "Type"
      config.tooltipFields.archetypeLabel = "Generic"
    end
  end
  config.tooltipFields.archetypeLabel = project45util.colorText("#ea9931", config.tooltipFields.archetypeLabel or "???")

  -- Append upgrade cost (default 0)
  local upgradeCost = deepConfigParameter( 0, "augment", "cost")
  config.tooltipFields.upgradeCostLabel = project45util.colorText(upgradeCost > 0 and "#96cbe7" or "#777777", string.format("^shadow;Upgrade Cost: %d", upgradeCost))
  config.tooltipFields.itemDescriptionUpgradeCostLabel = project45util.colorText(upgradeCost > 0 and "#96cbe7" or "#777777", string.format("^shadow;U. Cost: %d", upgradeCost))

  -- Append technical info
  local techInfo = configParameter("technicalInfo")
  if techInfo then
    config.tooltipFields.technicalLabel = project45util.colorText("#ffd495",techInfo)
  else
    config.tooltipFields.technicalLabel = project45util.colorText("#a0a0a0","No technical info.")
  end
  
  config.tooltipFields.rarityLabel = rarityConversions[configParameter("isUnique", false) and "unique" or string.lower(configParameter("rarity", "common"))]

  -- change stats field
  local statLimit = 7
  local stats = 1
  local specialField = set.new({"level", "pureStatMod", "randomStatParams", "stackLimit"})
  local specialCases = set.new({"bulletsPerReload"})
  local isRandomStats = deepConfigParameter(false, "augment", "stat", "randomStatParams")
  local registeredRandomStats = {}

  for stat, op in pairs(deepConfigParameter({}, "augment", "stat")) do
    if not specialField[stat] then
      for mod, val in pairs(op) do
        if not registeredRandomStats[stat] then
          if stats > statLimit then
            config.tooltipFields.stat7TitleLabel = "^#7e7e7e;..."
            config.tooltipFields.stat7Label = "^#7e7e7e;..."
            break
          end
          local formattedStat, formattedVal = formatStat(stat, mod, val, type(val) == "string")
          config.tooltipFields["stat" .. stats .. "TitleLabel"] = formattedStat
          config.tooltipFields["stat" .. stats .. "Label"] = formattedVal
          stats = stats + 1
          registeredRandomStats[stat] = isRandomStats
        end
      end
      if stats > statLimit then
        config.tooltipFields.stat7TitleLabel = "^#7e7e7e;..."
        config.tooltipFields.stat7Label = "^#7e7e7e;..."
        break
      end

    elseif stat == "level" then
      if stats + 1 <= statLimit then
        config.tooltipFields["stat" .. stats .. "TitleLabel"] = "^#a8e6e2;Level"
        config.tooltipFields["stat" .. stats .. "Label"] = "^#a8e6e2;+" .. op
        stats = stats + 1
      else
        config.tooltipFields.stat7TitleLabel = "^#7e7e7e;..."
        config.tooltipFields.stat7Label = "^#7e7e7e;..."
        break
      end
    end
  end

  return config, parameters
end