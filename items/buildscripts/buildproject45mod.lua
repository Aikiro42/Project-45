require "/scripts/project45/project45util.lua"
require "/scripts/versioningutils.lua"
require "/scripts/util.lua"
require "/scripts/set.lua"

function build(directory, config, parameters, level, seed)
  
  local extrinsicModSlots = set.new({
    "rail",
    "sights",
    "muzzle",
    "underbarrel",
    "stock"
  })

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

  -- if no set upgrade cost,
  -- extrinsic mods are free,
  -- intrinsic mods cost 1 upgrade capacity
  if not config.augment.upgradeCost then
    config.augment.upgradeCost = extrinsicModSlots[config.augment.slot or config.slot] and 0 or 1
  end

  config.tooltipFields = config.tooltipFields or {}
  config.tooltipFields.categoryLabel = project45util.categoryStrings[config.augment.category or "universal"]

  if config.category == "Ammo Mod" or config.category == "Converter Mod" then
    config.tooltipFields.slotLabel = "^#9da8af;Ammo"
  
  elseif config.category == "Stat Mod" then
    local statSlots = {
      baseDamage = "^#FF9000;Base Damage",
      fireTime = "^#FFD400;Fire Time",
      reloadCost = "^#b0ff78;Reload Cost",
      critChance = "^#FF6767;Crit Chance",
      critDamage = "^#FF6767;Crit Damage",
      multiple = "^#A8E6E2;Multiple",
      level = "^#a8e6e2;Level"
    }
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

  config.tooltipFields.technicalLabel = config.augment.upgradeCost > 1
    and project45util.colorText("#FF5050", string.format("Cost: %d\n", config.augment.upgradeCost))
    or ""

  if config.technicalInfo then
    config.tooltipFields.technicalLabel = config.tooltipFields.technicalLabel .. "^#ffd495;" .. config.technicalInfo .. "^reset;\n"
  end
  if config.statInfo then
    config.tooltipFields.technicalLabel = config.tooltipFields.technicalLabel .. "^#b2e89d;" .. config.statInfo .. "^reset;\n"
  end

  return config, parameters
end