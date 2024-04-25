require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"

function apply(output, augment)

  local input = output:descriptor()
  local modInfo = output:instanceValue("project45GunModInfo")

  local configParameterStat = function(stat, default)
    return output:instanceValue("primaryAbility", {})[stat] or default
  end

  local statModifiers = output:instanceValue("statModifiers", {})

  local statConfig = root.assetJson("/configs/project45/project45_statmod.config")

  local newPrimaryAbility = {}

  -- stat lists composed of string-defaultValue pairs
  local statList = statConfig.statDefaults or {}

  -- stat flags
  local isRestrictedStat = set.new(statConfig.restrictedStats or {})
  local isConfigStat = set.new(statConfig.configStats or {})
  local isRestrictedGroup = set.new(statConfig.restrictedGroups or {})
  local isIntegerStat = set.new(statConfig.integerStats or {})
  local isBadStat = set.new(statConfig.badStat or {})
  local isStatGroup = set.new(statConfig.statGroups or {})

  -- stat properties
  local statGroup = statConfig.statGroupAssignments or {}
  local statBounds = statConfig.statBounds or {}

  -- group properties
  local groupStats = {}
  for stat, group in pairs(statGroup) do
    if not groupStats[group] then
      groupStats[group] = {stat}
    else
      table.insert(groupStats[group], stat)
    end
  end

  -- retrieves the base value of a stat
  local baseStat = function(stat)

    local savedBaseStat = nil

    if statGroup[stat] then
      savedBaseStat = (statModifiers[statGroup[stat]] or {
        base = {}
      }).base[stat]
    else
      savedBaseStat = (statModifiers[stat] or {}).base
    end

    if savedBaseStat == nil then
      -- base stat not saved; retrieve from item
      if isConfigStat[stat] then -- retrieve strictly from config
        return (output.config.primaryAbility or {})[stat] or statList[stat]
      end
      -- retrieve from parameters or config
      return output:instanceValue("primaryAbility", {})[stat] or statList[stat]
    else
      -- base stat saved, retrieve it
      return savedBaseStat
    end

  end

  -- SECTION: SPECIAL STAT CASES

  if augment.maxAmmo then

    statModifiers.maxAmmo = statModifiers.maxAmmo or {
      base = baseStat("maxAmmo")
    }
    statModifiers.bulletsPerReload = statModifiers.bulletsPerReload or {
      base = baseStat("bulletsPerReload")
    }

    if statModifiers.bulletsPerReload.base >= statModifiers.maxAmmo.base and not augment.bulletsPerReload then
      augment.bulletsPerReload = augment.maxAmmo
    end

  end

  -- Alter fireTime (stat)
  if augment.fireTimeStat then
    statModifiers.fireTime = statModifiers.fireTime or {
      base = {}
    }
    
    if augment.fireTimeStat.rebase then
      statModifiers.fireTime.base.fireTime = augment.fireTimeStat.rebase
    end
    
    if augment.fireTimeStat.rebaseMult then
      statModifiers.fireTime.base.fireTime = baseStat("fireTime") * augment.fireTimeStat.rebaseMult
    end

    -- prompt change
    augment.fireTime = augment.fireTime or {}

    -- to be REALLY safe,
    augment.fireTimeStat = nil

  end
  
  -- Alter cycleTime (stat)
  if augment.cycleTime then
    statModifiers.fireTime = statModifiers.fireTime or {
      base = {}
    }

    if augment.cycleTime.rebase then
      statModifiers.fireTime.base.cycleTime = augment.cycleTime.rebase
    end

    if augment.cycleTime.rebaseMult then
      statModifiers.fireTime.base.cycleTime = baseStat("cycleTime") * augment.cycleTime.rebaseMult
    end

    -- prompt change
    augment.fireTime = augment.fireTime or {}

    -- to be REALLY safe,
    augment.cycleTime = nil

  end

  -- Alter general Fire Rate
  if augment.fireTime then
    statModifiers.fireTime = statModifiers.fireTime or {
      base = {}
    }
    for _, fireTimeStat in ipairs(groupStats.fireTime) do
      statModifiers.fireTime.base[fireTimeStat] = baseStat(fireTimeStat)
    end

    local newCockTime = statModifiers.fireTime.base.cockTime
    local newMidCockDelay = statModifiers.fireTime.base.midCockDelay
    local newCycleTime = statModifiers.fireTime.base.cycleTime
    local newFireTime = statModifiers.fireTime.base.fireTime

    local newChargeTime = statModifiers.fireTime.base.chargeTime
    local newOverchargeTime = statModifiers.fireTime.base.overchargeTime

    local minFireTime = math.min(0.001, type(newCycleTime) == "table" and newCycleTime[1] or newCycleTime, newCockTime,
        newFireTime)

    if augment.fireTime.additive then
      statModifiers.fireTime.additive = (statModifiers.fireTime.additive or 0) + augment.fireTime.additive
    end

    if augment.fireTime.multiplicative then
      statModifiers.fireTime.multiplicative = (statModifiers.fireTime.multiplicative or 1) +
                                                  augment.fireTime.multiplicative
    end

    --[[
        Recall: calculation of displayed fire time
        If gun is manualFeed:
            fireTime* = cockTime + fireTime + chargeTime
        else:
            fireTime* = cycleTime + fireTime + chargeTime
        --]]

    -- apply fireTime modifiers

    local fireTimeAdd, chargeAdd, overchargeAdd

    if statModifiers.fireTime.additive then
      local isSemi = output.config.semi
      if input.parameters.semi ~= nil then
        isSemi = input.parameters.semi
      end

      local distributedStats = (isSemi and newChargeTime > 0) and 2 or 1

      fireTimeAdd = statModifiers.fireTime.additive / distributedStats

      chargeAdd = fireTimeAdd
      if newChargeTime > 0 and not isSemi then
        chargeAdd = statModifiers.fireTime.additive
      end

      -- ensures that same amount of time will be spent overcharging
      overchargeAdd = 0
      if newChargeTime > 0 and newOverchargeTime > 0 then
        overchargeAdd = newOverchargeTime * chargeAdd / newChargeTime
      end

    end

    -- modify cycle time to be at least minFiretime
    if type(newCycleTime) == "table" then
      newCycleTime = {math.max(minFireTime,
          moddedStat(newCycleTime[1], fireTimeAdd, statModifiers.fireTime.multiplicative, true)),
                      math.max(minFireTime,
          moddedStat(newCycleTime[2], fireTimeAdd, statModifiers.fireTime.multiplicative, true))}
    else
      newCycleTime = math.max(minFireTime,
          moddedStat(newCycleTime, fireTimeAdd, statModifiers.fireTime.multiplicative, true))
    end

    newCockTime = math.max(minFireTime,
        moddedStat(newCockTime, fireTimeAdd, statModifiers.fireTime.multiplicative, true))
    newFireTime = math.max(minFireTime,
        moddedStat(newFireTime, fireTimeAdd, statModifiers.fireTime.multiplicative, true))

    if newChargeTime > 0 then
      newChargeTime = math.max(0, moddedStat(newChargeTime, chargeAdd, statModifiers.fireTime.multiplicative, true))
    end
    if newOverchargeTime > 0 then
      newOverchargeTime = math.max(0, moddedStat(newOverchargeTime, overchargeAdd,
          statModifiers.fireTime.multiplicative, true))
    end

    newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
      cockTime = newCockTime,
      cycleTime = newCycleTime,
      chargeTime = newChargeTime,
      overchargeTime = newOverchargeTime,
      fireTime = newFireTime
    })

    -- to be REALLY safe,
    augment.fireTime = nil

  end

  -- Alter level
  if augment.level then
    output:setInstanceValue("level", math.min(10, (input.parameters.level or output.config.level) + augment.level))
  end

  -- SECTION: GENERAL CHANGES

  for stat, op in pairs(augment) do

    local restricted = isRestrictedStat[stat] or isRestrictedGroup[statGroup[stat] or "???"]

    -- individual stats
    if statList[stat] then

      if not isStatGroup[stat] -- not a group name
      and not statGroup[stat] then -- is individual stat

        statModifiers[stat] = statModifiers[stat] or {}

        -- can only rebase restricted stats
        if op.rebase then
          statModifiers[stat].base = op.rebase
        end

        if op.rebaseMult then
          statModifiers[stat].base = baseStat(stat) * op.rebaseMult
        end


        if not restricted then
          
          -- initialize statModifiers entry as necessary
          statModifiers[stat] = statModifiers[stat] or {base=baseStat(stat)}

          -- initialize mod table
          local mod = {}

          -- update modifiers
          if op.additive then
            statModifiers[stat].additive = (statModifiers[stat].additive or 0) + op.additive
          end

          if op.multiplicative then
            statModifiers[stat].multiplicative = (statModifiers[stat].multiplicative or 1) + op.multiplicative
          end

          mod[stat] = moddedStat(
            statModifiers[stat].base,
            statModifiers[stat].additive,
            statModifiers[stat].multiplicative,
            isBadStat[stat],
            isIntegerStat[stat],
            statBounds[stat]
          )
          -- apply values
          newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, mod)

        end

      elseif statGroup[stat] then
        
        -- can only rebase restricted stats
        if op.rebase then
          statModifiers[statGroup[stat]] = statModifiers[statGroup[stat]] or {
            base = {}
          }
          statModifiers[statGroup[stat]].base[stat] = op.rebase
        end

        if op.rebaseMult then
          statModifiers[statGroup[stat]].base[stat] = baseStat(stat) * op.rebaseMult
        end

        if not restricted then
          
          -- initialize statModifiers entry as necessary
          statModifiers[statGroup[stat]] = statModifiers[statGroup[stat]] or {
            base = {}
          }
          for _, groupStat in ipairs(groupStats[statGroup[stat]]) do
            statModifiers[statGroup[stat]].base[groupStat] = baseStat(groupStat)
          end


          local mod = {}

          -- update modifiers
          if op.additive then
            statModifiers[statGroup[stat]].additive =
                (statModifiers[statGroup[stat]].additive or 0) + op.additive
          end

          if op.multiplicative then
            statModifiers[statGroup[stat]].multiplicative =
                (statModifiers[statGroup[stat]].multiplicative or 1) + op.multiplicative
          end

          for baseStat, baseValue in pairs(statModifiers[statGroup[stat]].base) do
            mod[baseStat] = moddedStat(baseValue, statModifiers[statGroup[stat]].additive,
                statModifiers[statGroup[stat]].multiplicative, isBadStat[baseStat], isIntegerStat[baseStat],
                statBounds[baseStat])
          end

          newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, mod)

        end

      end
    end

  end

  -- merge changes
  -- output:setInstanceValue("primaryAbility", sb.jsonMerge(input.parameters.primaryAbility, newPrimaryAbility))
  output:setInstanceValue("primaryAbility", sb.jsonMerge(output:instanceValue("primaryAbility"), newPrimaryAbility))
  output:setInstanceValue("statModifiers", statModifiers)

  return output

end

function moddedStat(base, additive, multiplicative, isDiv, isInt, bounds)

  additive = additive or 0
  multiplicative = multiplicative or 1
  local result = 0
  if isDiv then
    result = (base / multiplicative) + additive
  else
    result = base * multiplicative + additive
  end

  if bounds then
    local lowerBound = bounds[1]
    local upperBound = bounds[2]
    if lowerBound and upperBound then
      result = util.clamp(result, lowerBound, upperBound)
    elseif lowerBound then
      result = math.max(lowerBound, result)
    elseif upperBound then
      result = math.min(upperBound, result)
    end
  end

  if isInt then
    return math.ceil(result)
  end

  return result

end
