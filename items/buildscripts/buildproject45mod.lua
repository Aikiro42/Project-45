require "/scripts/project45/project45util.lua"
require "/scripts/versioningutils.lua"
require "/scripts/util.lua"

local categoryStrings = {
  ballistic = "^#51bd3b; Ballistic^reset;",
  energy = "^#d29ce7; Energy^reset; ",
  generic = "^#FFFFFF;Ѻ Generic^reset; ",
  experimental = "^#A8E6E2; Experimental^reset; ",
  special = "^#e2c344;© Special^reset; ",
  universal = "^#cfcfcf;¤ Universal^reset;"
}

function build(directory, config, parameters, level, seed)
  
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

  config.tooltipFields = config.tooltipFields or {}
  config.tooltipFields.categoryLabel = categoryStrings[config.augment.category or "universal"]
  config.tooltipFields.slotLabel = "^#9da8af;" ..  (
    ((config.category == "Ammo Mod" or config.category == "Converter Mod") and "Ammo")
    or (config.category == "Stat Mod" and "Stat")
    or project45util.capitalize(config.augment.slot or config.slot or "N/A")
  )
  config.tooltipFields.archetypeLabel = "^#ea9931;" .. (project45util.capitalize(config.augment.archetype) or config.archetype or "^#a0a0a0;N/A")
  config.tooltipFields.technicalLabel = "^#ffd495;" .. (config.technicalInfo or "") .. "\n^#b2e89d;" .. (config.statInfo or "")

  return config, parameters
end