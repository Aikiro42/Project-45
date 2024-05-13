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
    
  local specialField = {
    randomStats = true
  }    
  
  -- get list of possible stats to modify
  local possibleStats = {nil}    
  for stat, modifier in pairs(config.augment.stat) do
    if not specialField[stat] then
      table.insert(possibleStats, stat)
    end
  end
  
  -- set upgrade cost to be 1/2 of modified stats
  local nStats = math.ceil(#possibleStats / 2)
  config.augment.cost = math.ceil(nStats/2)


  if parameters.seed then

    -- init seeded rng
    local rng = sb.makeRandomSource(parameters.seed)
    
    -- choose n/2 stats from n possible stats, put in `modifications` table
    local modifications = {}
    for n=1, nStats do
      local chosenStat = table.remove(possibleStats, (rng:randu32() % #possibleStats) + 1)
      modifications[chosenStat] = config.augment.stat[chosenStat]
    end

    -- For each chosen stat and its operations
    for stat, modification in pairs(modifications) do

      -- get list of possible operations to apply
      local possibleOps = {nil}
      for op, value in pairs(modification) do
        if type(value) == "table" then
          table.insert(possibleOps, op)
        end
      end

      -- if there are valid operations,
      if #possibleOps > 0 then
        
        -- choose one among them and apply
        local chosenOp = table.remove(possibleOps, (rng:randu32() % #possibleOps) + 1)
        local chosenValueVector = modification[chosenOp]
        config.augment.stat[stat][chosenOp] = generateRandomStat(chosenValueVector, rng)

        -- nullify unchosen random ops
        for _, op in ipairs(possibleOps) do
          config.augment.stat[stat][op] = nil
        end
      end

    end

    -- nullify unchosen stats
    for _, stat in ipairs(possibleStats) do
      config.augment.stat[stat] = nil
    end

    parameters.shortdescription = string.format("%s%s", config.shortdescription, parameters.seed and (" #" .. parameters.seed) or "")
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