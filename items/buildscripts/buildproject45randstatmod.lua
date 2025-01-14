---@diagnostic disable: lowercase-global
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

  local useSeed = configParameter("seed", seed)


  construct(config, "augment") -- make sure config.augment exists
  
  -- generate seed if supposed to be seeded
  -- but seed is not established
  if not useSeed then
    useSeed = math.floor(math.random() * 2147483647)
    parameters.seed = useSeed
  end

  if configParameter("noSeed") then
    useSeed = nil
    config.seed = nil
    parameters.seed = nil
  end

  local randomStatConfig = deepConfigParameter({}, "augment", "randomStat")
  local randomStatParams = randomStatConfig.parameters or {}
  local specialField = {
    parameters = true,
    pureStatMod = true,
    stackLimit = true
  }
  

  -- get list of possible stats to modify
  local possibleStats = {nil}    
  for stat, modifier in pairs(randomStatConfig or {}) do
    if not specialField[stat] then
      table.insert(possibleStats, stat)
    end
  end
  
  -- set upgrade cost to be 1/2 of modified stats
  local nStats = math.min(#possibleStats, randomStatParams.chosenStatCount or math.ceil(#possibleStats / 2))
  local costPerStat = randomStatParams.costPerStat or 1
  config.augment.cost = math.ceil(costPerStat * nStats)  

  local rng = sb.makeRandomSource(useSeed or 0)

  if useSeed
  and not deepConfigParameter(nil, "augment", "stat")
  and randomStatConfig
  then

    -- init seeded rng

    -- choose n/2 stats from n possible stats, put in `modifications` table
    local modifications = {}
    for n=1, nStats do
      local chosenStat = table.remove(possibleStats, (rng:randu32() % #possibleStats) + 1)
      modifications[chosenStat] = randomStatConfig[chosenStat]
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
        randomStatConfig[stat][chosenOp] = generateRandomStat(chosenValueVector, rng)

        -- nullify unchosen random ops
        for _, op in ipairs(possibleOps) do
          randomStatConfig[stat][op] = nil
        end
      end

    end

    -- nullify unchosen stats
    for _, stat in ipairs(possibleStats) do
      randomStatConfig[stat] = nil
    end
    
    -- done constructing stats, remove parameters
    randomStatConfig.parameters = nil

    construct(parameters, "augment")
    parameters.augment.stat = randomStatConfig
  end

  parameters.shortdescription = string.format("%s%s", config.shortdescription, useSeed and (" #" .. useSeed) or "")

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