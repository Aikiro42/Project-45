require "/scripts/project45/project45util.lua"
require "/scripts/versioningutils.lua"
require "/scripts/util.lua"
require "/scripts/set.lua"
require "/items/buildscripts/buildproject45mod.lua"

local unrandBuild = build

function build(directory, config, parameters, level, seed)

  parameters = parameters or {}

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

  construct(config, "augment")
  construct(parameters, "augment")

  local randomStatInfo = nil

  if config.modCategory == "statMod"
  and config.augment.randomStats
  and (parameters.seed or seed) then
    
    parameters.seed = parameters.seed or seed
    
    local rng = sb.makeRandomSource(parameters.seed)
    
    randomStatInfo = ""
    -- util.round(x, 1)
    config.archetype = nil
    config.slot = nil

    for _, statName in ipairs(statNames) do
      if config.augment[statName] then
        config.slot = config.slot and "multiple" or statName 

        -- choose a random operation
        local opName = "additive"
        if config.augment[statName].additive and
        config.augment[statName].multiplicative then
          opName = rng:randb() and "additive" or "multiplicative"
        else
          opName = not config.augment[statName].additive and "multiplicative" or opName
        end

        if config.augment[statName][opName] then

          if config.archetype then
            config.archetype = config.archetype ~= opName and "mixed" or opName
          else
            config.archetype = opName
          end

          -- generate stat if statname and opname exists
          config.augment[statName][opName] = generateRandomStat(config.augment[statName][opName], rng, 3)
          config.augment[statName][opName == "additive" and "multiplicative" or "additive"] = nil
          -- modify tooltip field info
          local statValue = config.augment[statName][opName]
          if statValue then
            statValue = statValue * (opName == "additive" and additiveStatDescMults[statName] or 1)
            local operand = statValue > 0 and "+" or ""
          
            local statSuffix = ""
            if opName == "multiplicative" then
              statSuffix = isDiv[statName] and "d" or "x"
            else
              statSuffix = additiveStatUnits[statName] or ""
            end

            randomStatInfo = randomStatInfo .. string.format("%s %s%.1f%s^reset;\n",
              statSlots[statName],
              operand,
              statValue,
              statSuffix
            )
          end

        end
        
      end
    
    end
    
    config.archetype = project45util.capitalize(config.archetype)
    local basePrice = (parameters.price or config.price)
    parameters.price = math.floor(rng:randf(basePrice/3, basePrice*3) * 0.1)
  else
    -- shop preview goes here
  end

  return unrandBuild(directory, config, parameters, level, seed, randomStatInfo)
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