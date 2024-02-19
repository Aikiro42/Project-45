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

  construct(config, "augment")  -- make sure config.augment exists

  -- if no set upgrade cost,
  -- extrinsic mods are free,
  -- intrinsic mods cost 1 upgrade capacity
  if not deepConfigParameter(nil, "augment", "upgradeCost") then
    config.augment.upgradeCost = extrinsicModSlots[deepConfigParameter(configParameter("slot"), "augment", "slot")] and 0 or 1
  end

  -- Change category label
  config.tooltipFields.categoryLabel = root.assetJson("/configs/project45/project45_generalconfig.config:categoryStrings", {})[deepConfigParameter("universal", "augment", "category")] or ""

  -- Change slot label if ammo or converter mod
  if configParameter("modCategory") == "ammoMod" or configParameter("modCategory") == "converterMod" then
    config.tooltipFields.slotLabel = "^#9da8af;Ammo"

  -- Change slot label if stat mod
  elseif configParameter("modCategory") == "statMod" then
    config.tooltipFields.slotTitleLabel = "Stat"
    config.tooltipFields.slotLabel = statSlots[configParameter("slot")]
  
  else
    config.tooltipFields.slotLabel = "^#9da8af;" ..
      project45util.capitalize(deepConfigParameter(configParameter("slot", "N/A"), "augment", "slot"))
  
  end

  config.tooltipFields.archetypeLabel = ""
  if configParameter("modCategory") == "gunMod" then
    config.tooltipFields.archetypeTitleLabel = "Mod Type"
    if not configParameter("archetype") then
      if extrinsicModSlots[deepConfigParameter(configParameter("slot"), "augment", "slot")] then
        config.tooltipFields.archetypeLabel = "^#ea9931;Extrinsic"
      else
        config.tooltipFields.archetypeLabel = "^#ea9931;Intrinsic"  
      end
    end    
  elseif configParameter("modCategory") == "ammoMod" then
      config.tooltipFields.archetypeTitleLabel = "Ammo Archetype"
      config.tooltipFields.archetypeLabel = "^#ea9931;" .. project45util.capitalize(deepConfigParameter("augment","archetype"))
  
  else
    if configParameter("modCategory") == "abilityMod" then
      config.tooltipFields.archetypeTitleLabel = "Ability Type"
    elseif configParameter("modCategory") == "statMod" then
      config.tooltipFields.archetypeTitleLabel = "Application"
    end
    config.tooltipFields.archetypeLabel = "^#ea9931;" .. (
      project45util.capitalize(deepConfigParameter("augment","archetype"))
      or config.archetype
      or "^#a0a0a0;N/A"
    )
  end

  -- Append upgrade cost (default 0)
  config.tooltipFields.technicalLabel = project45util.colorText("#777777", string.format("Upgrade Cost: %d\n", deepConfigParameter(0, "augment", "upgradeCost")))

  -- Append technical info
  local techInfo = configParameter("technicalInfo")
  if techInfo then
    config.tooltipFields.technicalLabel = config.tooltipFields.technicalLabel .. "^#ffd495;" .. techInfo .. "^reset;\n"
  end

  -- Append stat info
  local statInfo = configParameter("statInfo")
  if statInfo then
    config.tooltipFields.technicalLabel = config.tooltipFields.technicalLabel .. "^#b2e89d;" .. statInfo .. "^reset;\n"
  end

  config.tooltipFields.rarityLabel = rarityConversions[configParameter("isUnique", false) and "unique" or string.lower(configParameter("rarity", "common"))]

  return config, parameters
end