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

  construct(config, "augment", "stat") -- make sure config.augment.stat exists
  construct(parameters, "augment", "stat") -- make sure config.augment.stat exists
  
  -- generate seed if supposed to be seeded
  -- but seed is not established
  if not (parameters.noSeed or configParameter("seed", seed)) then
    parameters.seed = math.floor(math.random() * 2147483647)
  end

  local randomStatParams = config.augment.stat.randomStatParams or {}
  local specialField = {
    randomStatParams = true,
    pureStatMod = true,
    stackLimit = true
  }
  
  -- get list of possible stats to modify
  local possibleStats = {nil}    
  for stat, modifier in pairs(config.augment.stat) do
    if not specialField[stat] then
      table.insert(possibleStats, stat)
    end
  end
  
  -- set upgrade cost to be 1/2 of modified stats
  local nStats = math.min(#possibleStats, randomStatParams.chosenStatCount or math.ceil(#possibleStats / 2))
  local costPerStat = randomStatParams.costPerStat or 1
  config.augment.cost = math.ceil(costPerStat * nStats)
  
  if parameters.seed
  and not parameters.augment.stat.randomized
  and config.augment.stat.randomStatParams then

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
    
    parameters.augment.stat.randomized = true
    parameters.augment.stat = config.augment.stat
    parameters.shortdescription = string.format("%s%s", config.shortdescription, parameters.seed and (" #" .. parameters.seed) or "")
  else
    -- TEST: 
    -- config.augment.stat = parameters.augment.stat
    parameters.augment.stat = nil
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