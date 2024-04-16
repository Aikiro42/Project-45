require "/scripts/project45/project45util.lua"
require "/scripts/util.lua"

function build(directory, config, parameters, level, seed)

  local statColors = {
    baseDamage = "#FF9000",
    fireTime = "#FFD400",
    reloadCost = "#b0ff78",
    critChance = "#FF6767",
    wildcard = "#A8E6E2",
    god = "#FFFFFF",
    level = "#a8e6e2"
  }

  local configParameter = function (key, default)
    if parameters[key] ~= nil then
      return parameters[key]
    elseif config[key] ~= nil then
      return config[key]
    else
      return default
    end
  end

  --[[
  local statModColors = {}
  statModColors["project45-damageaddmod"] = {"addDamageCountLabel", "#FF9000"}
  statModColors["project45-damagemultmod"] = {"multDamageCountLabel", "#FF9000"}
  statModColors["project45-firetimeaddmod"] = {"addFireTimeCountLabel", "#FFD400"}
  statModColors["project45-firetimemultmod"] = {"addDamageCountLabel", "#FFD400"}
  statModColors["project45-reloadcostaddmod"] = {"addDamageCountLabel", "#b0ff78"}
  statModColors["project45-reloadcostmultmod"] = {"addDamageCountLabel", "#b0ff78"}
  statModColors["project45-critchanceaddmod"] = {"addDamageCountLabel", "#FF6767"}
  statModColors["project45-critchancemultmod"] = {"addDamageCountLabel", "#FF6767"}
  statModColors["project45-critdamageaddmod"] = {"addDamageCountLabel", "#FF6767"}
  statModColors["project45-critdamagemultmod"] = {"addDamageCountLabel", "#FF6767"}
  statModColors["project45-levelmod"] = {"addDamageCountLabel", "#A8E6E2"}
  statModColors["project45-maxlevelmod"] = {"addDamageCountLabel", "#A8E6E2"}
  statModColors["project45-godmod"] = {"addDamageCountLabel", "#FFFFFF"}
  statModColors["project45-teststatmod"] = {"addDamageCountLabel", "#FFFFFF"}
  statModColors["project45-wildcardstatmod"] = {"addDamageCountLabel", "#d29ce7"}


  local statMods = {}
  for _, item in ipairs(configParameter("disassembledItems")) do
  end
  --]]



  return config, parameters
end