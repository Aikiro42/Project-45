require "/scripts/project45/project45util.lua"
require "/scripts/versioningutils.lua"
require "/scripts/util.lua"
require "/scripts/set.lua"
require "/items/buildscripts/buildproject45mod.lua"

local unrandBuild = build

function build(directory, config, parameters, level, seed)

  parameters = parameters or {}

  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end

  local statSlots = {
    baseDamage = "^#FF9000;Base Damage",
    fireTime = "^#FFD400;Fire Time",
    reloadCost = "^#b0ff78;Reload Cost",
    critChance = "^#FF6767;Crit Chance",
    critDamage = "^#FF6767;Crit Damage",
    multiple = "^#A8E6E2;Multiple",
    level = "^#a8e6e2;Level"
  }

  local statNames = {
    "baseDamage",
    "reloadCost",
    "fireTime",
    "critChance",
    "critDamage"
  }

  local isPercentValue = set.new({
    "critChance"
  })
  
  local isDiv = set.new({
    "reloadCost",
    "fireTime",
  })

  local additiveStatDescMults = {
    fireTime = 1000,
    critChance = 100
  }

  local additiveStatUnits = {
    fireTime = "ms",
    critChance = "%"
  }

  construct(config, "augment") -- make sure config.augment exists

  -- generate seed if supposed to be seeded
  -- but seed is not established
  if not (parameters.noSeed or configParameter("seed", seed)) then
    parameters.seed = math.floor(math.random() * 2147483647)
  end

  if config.modCategory == "statMod"
  and config.augment.randomStats
  and not parameters.augment
  and configParameter("seed", seed) then
    
    construct(parameters, "augment", "stat")

    -- generate random source
    parameters.seed = configParameter("seed", seed)
    local rng = sb.makeRandomSource(parameters.seed)
    
    -- prepare tooltip information
    parameters.statInfo = ""
    parameters.archetype = nil
    parameters.slot = nil

    -- begin stat generation process
    for _, statName in ipairs(statNames) do
      if config.augment.stat[statName] then -- generate stat if it exists

        -- indicate if it modifies multiple stats or not
        parameters.slot = parameters.slot and "multiple" or statName 

        -- choose a random operation
        local opName = "additive"
        if  config.augment.stat[statName].additive
        and config.augment.stat[statName].multiplicative then
          opName = rng:randb() and "additive" or "multiplicative"
        else
          opName = not config.augment.stat[statName].additive and "multiplicative" or opName
        end

        -- generate random stat if operation was chosen successfully
        if config.augment.stat[statName][opName] then

          -- indicate if it does exclusively additive/multiplicative ops or both
          if parameters.archetype then
            parameters.archetype = parameters.archetype ~= opName and "mixed" or opName
          else
            parameters.archetype = opName
          end

          -- generate stat if statname and opname exists, truncate to 3 decimal places
          construct(parameters.augment, "stat", statName, opName)
          parameters.stat.augment[statName][opName] = generateRandomStat(config.augment[statName][opName], rng, 3)
          parameters.stat.augment[statName][opName == "additive" and "multiplicative" or "additive"] = 0
          
          -- modify tooltip field info
          local statValue = parameters.stat.augment[statName][opName]
          if statValue then
            statValue = statValue * (opName == "additive" and additiveStatDescMults[statName] or 1)
            local operand = statValue > 0 and "+" or ""
          
            local statSuffix = ""
            if opName == "multiplicative" then
              statSuffix = isDiv[statName] and "d" or "x"
            else
              statSuffix = additiveStatUnits[statName] or ""
            end

            parameters.statInfo = parameters.statInfo .. string.format("%s %s%.1f%s^reset;\n",
              statSlots[statName],
              operand,
              statValue,
              statSuffix
            )
          end

        end
        
      end
    
    end
    
    parameters.archetype = project45util.capitalize(parameters.archetype)
    if not parameters.price then
      local basePrice = config.price or 1000
      parameters.price = math.floor(rng:randf(basePrice/3, basePrice*3) * 0.1)
    end
  end

  return unrandBuild(directory, config, parameters, level, seed)
end

function generateRandomStat(statVector, rng, truncate)
  if not statVector then
    return nil
  end
  local stat = 0
  if type(statVector) == "table" then
    local lo = math.min(statVector[1], statVector[2])
    local hi = math.max(statVector[1], statVector[2])
    stat = rng:randf(lo, hi)
  else
    if statVector > 0 then
      stat = rng:randf(0, statVector)
    else
      stat = rng:randf(statVector, 0)
    end
  end
  if truncate then
    stat = project45util.truncatef(stat, truncate)
  end
  return stat ~= 0 and stat or nil
end