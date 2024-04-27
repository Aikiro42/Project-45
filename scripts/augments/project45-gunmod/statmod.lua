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
  local isGroupMember = statGroup -- for readability
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

    if isGroupMember[stat] then
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
      else
        local primaryAbility = sb.jsonMerge(output.config.primaryAbility or {}, output.parameters.primaryAbility or {})
        -- retrieve from parameters or config
        return primaryAbility[stat] or statList[stat]
      end
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
          getModifiedStat(newCycleTime[1], fireTimeAdd, statModifiers.fireTime.multiplicative, true)),
                      math.max(minFireTime,
          getModifiedStat(newCycleTime[2], fireTimeAdd, statModifiers.fireTime.multiplicative, true))}
    else
      newCycleTime = math.max(minFireTime,
          getModifiedStat(newCycleTime, fireTimeAdd, statModifiers.fireTime.multiplicative, true))
    end

    newCockTime = math.max(minFireTime,
        getModifiedStat(newCockTime, fireTimeAdd, statModifiers.fireTime.multiplicative, true))
    newFireTime = math.max(minFireTime,
        getModifiedStat(newFireTime, fireTimeAdd, statModifiers.fireTime.multiplicative, true))

    if newChargeTime > 0 then
      newChargeTime = math.max(0, getModifiedStat(newChargeTime, chargeAdd, statModifiers.fireTime.multiplicative, true))
    end
    if newOverchargeTime > 0 then
      newOverchargeTime = math.max(0, getModifiedStat(newOverchargeTime, overchargeAdd,
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

  local updateStatModifiers = function(stat, rebase, rebaseMult, additive, multiplicative)
    -- do not modify stats not tracked by config
    if not statList[stat] then return end

    local primaryAbilityMod = {}
    
    -- group or pure individual stat
    if isStatGroup[stat] or not isGroupMember[stat] then
      
      -- initialize statModifiers entry
      statModifiers[stat] = statModifiers[stat] or {
        base = isStatGroup[stat] and {} or baseStat(stat),
        additive = 0,
        multiplicative = 1
      }
      
      -- initialize entry of group
      if isStatGroup[stat] then
        for _, substat in ipairs(groupStats[stat]) do
          statModifiers[stat].base[substat] = baseStat(substat)
        end
      end
      
      -- rebase/rebaseMult if pure individual
      if not isGroupMember[stat] then
        if rebase then
          statModifiers[stat].base = rebase
        end
        if rebaseMult then
          statModifiers[stat].base = baseStat(stat) * rebaseMult
        end
      end

      if additive then
        statModifiers[stat].additive = (statModifiers[stat].additive or 0) + additive
      end
      if multiplicative then
        statModifiers[stat].multiplicative = (statModifiers[stat].multiplicative or 1) + multiplicative
      end

      if isStatGroup[stat] then
        for substat, subStatBase in ipairs(statModifiers[stat].base) do
          primaryAbilityMod[substat] = getModifiedStat(
            subStatBase,
            statModifiers[stat].additive,
            statModifiers[stat].multiplicative,
            isBadStat[substat],
            isIntegerStat[substat],
            statBounds[substat]
          )
        end
      elseif isGroupMember[stat] then  -- defensive programming baby
        primaryAbilityMod[stat] = getModifiedStat(
          statModifiers[stat].base,
          statModifiers[stat].additive,
          statModifiers[stat].multiplicative,
          isBadStat[stat],
          isIntegerStat[stat],
          statBounds[stat]
        )
      end
      
    -- group member stat
    else
      
      -- initialize statModifiers entry
      local group = statGroup[stat]
      statModifiers[group] = statModifiers[group] or {
        base = {},
        additive = 0,
        multiplicative = 1
      }
      statModifiers[group].base[stat] = baseStat(stat) -- should return the same value if it exists
      statModifiers[stat] = statModifiers[stat] or {
        additive = 0,
        multiplicative = 0
      }

      if rebase then
        statModifiers[group].base[stat] = rebase
      end

      if rebaseMult then
        statModifiers[group].base[stat] = baseStat(stat) * rebaseMult
      end

      if additive then
        statModifiers[stat].additive = (statModifiers[stat].additive or 0) + additive
      end

      if multiplicative then
        statModifiers[stat].multiplicative = (statModifiers[stat].multiplicative or 0) + multiplicative
      end

      local totalAdditive = (statModifiers[group].additive or 0) + (statModifiers[stat].additive or 0)
      local totalMultiplicative = (statModifiers[group].totalMultiplicative or 1) + (statModifiers[stat].totalMultiplicative or 0)

      primaryAbilityMod[stat] = getModifiedStat(
        baseStat(stat),
        totalAdditive,
        totalMultiplicative,
        isBadStat[stat],
        isIntegerStat[stat],
        statBounds[stat]
      )

    end

    newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, primaryAbilityMod)

  end

  local recalculateStat = function()
  end

  for stat, op in pairs(augment) do

    local restricted = false
    if isGroupMember[stat] then
      restricted = isRestrictedGroup[statGroup[stat]]
    elseif isStatGroup[stat] then
      restricted = isRestrictedGroup[stat]
    else
      restricted = isRestrictedStat[stat]
    end

    if restricted then
      -- FIXME: it doesn't really make sense to allow REBASING of restricted stat/groups
      updateStatModifiers(stat, op.rebase, op.rebaseMult, nil, nil)
    else
      updateStatModifiers(stat, op.rebase, op.rebaseMult, op.additive, op.multiplicative)
    end

  end

  -- merge changes
  -- output:setInstanceValue("primaryAbility", sb.jsonMerge(input.parameters.primaryAbility, newPrimaryAbility))
  output:setInstanceValue("primaryAbility", sb.jsonMerge(output:instanceValue("primaryAbility"), newPrimaryAbility))
  output:setInstanceValue("statModifiers", statModifiers)

  return output

end

function getModifiedStat(base, additive, multiplicative, isDiv, isInt, bounds)

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
