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
  local statAlias = statConfig.statAliases or {}
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

  -- Retrieves the base value of a stat in the following order until it gets a numerical value:
  -- 1. from the respective `statModifiers` entry of the stat
  -- 2. from the `statDefaults` dictionary in `statmod.config`
  -- @param stat: string
  -- * can either be a member or individual stat/alias
  local baseStat = function(stat)
    stat = statAlias[stat] or stat

    if isStatGroup[stat] then
      sb.logError("(statmod.lua) BASE STAT OF GROUP WAS QUERIED")
      return nil
    end

    local saved = nil
    if isGroupMember[stat] then
      saved = (statModifiers[statGroup[stat]] or {base={}}).base[stat]
    else
      saved = (statModifiers[stat] or {}).base
    end

    if not statList[stat] then
      sb.logError("(statmod.lua) UNREGISTERED STAT QUERIED")
    end

    return saved or statList[stat]

  end

  -- SECTION: SPECIAL STAT CASES

  if augment.maxAmmo then

    statModifiers.maxAmmo = statModifiers.maxAmmo or {
      base = baseStat("maxAmmo"),
      additive = 0,
      multiplicative = 1
    }
    statModifiers.bulletsPerReload = statModifiers.bulletsPerReload or {
      base = baseStat("bulletsPerReload"),
      additive = 0,
      multiplicative = 1
    }

    if statModifiers.bulletsPerReload.base >= statModifiers.maxAmmo.base and not augment.bulletsPerReload then
      augment.bulletsPerReload = augment.maxAmmo
    end

  end

  -- individual fireTimeGroup stats
  for _, fireTimeGroupStat in ipairs(groupStats.fireTimeGroup) do
    if augment[fireTimeGroupStat] then

      statModifiers.fireTimeGroup = statModifiers.fireTimeGroup or {
        base = {},
        additive = 0,
        multiplicative = 1
      }

      -- fireTimeGroup stats don't have their member entries in statModifiers because of the nature of their recalculation

      statModifiers.fireTimeGroup.base[fireTimeGroupStat] = statModifiers.fireTimeGroup.base[fireTimeGroupStat] or baseStat(fireTimeGroupStat)
  
      if augment[fireTimeGroupStat].rebase then
        statModifiers.fireTimeGroup.base[fireTimeGroupStat] = augment[fireTimeGroupStat].rebase
      end
      if augment[fireTimeGroupStat].rebaseMult then
        statModifiers.fireTimeGroup.base[fireTimeGroupStat] = statModifiers.fireTimeGroup.base[fireTimeGroupStat] * augment[fireTimeGroupStat].rebaseMult
      end
  
      -- prompt recalculation
      augment.fireTimeGroup = augment.fireTimeGroup or {}

      -- clear entry to prevent general case from covering this
      augment[fireTimeGroupStat] = nil
  
    end  
  end

  
  -- Alter general Fire Time
  if augment.fireTimeGroup then
    statModifiers.fireTimeGroup = statModifiers.fireTimeGroup or {
      base = {},
      additive = 0,
      multiplicative = 1
    }
    for _, fireTimeStat in ipairs(groupStats.fireTimeGroup) do
      statModifiers.fireTimeGroup.base[fireTimeStat] = baseStat(fireTimeStat)
    end

    local newCockTime = statModifiers.fireTimeGroup.base.cockTime
    local newMidCockDelay = statModifiers.fireTimeGroup.base.midCockDelay
    local newCycleTime = statModifiers.fireTimeGroup.base.cycleTime
    local newFireTime = statModifiers.fireTimeGroup.base.fireTime

    local newChargeTime = statModifiers.fireTimeGroup.base.chargeTime
    local newOverchargeTime = statModifiers.fireTimeGroup.base.overchargeTime

    local minFireTime = math.min(0.001, type(newCycleTime) == "table" and newCycleTime[1] or newCycleTime, newCockTime,
        newFireTime)

    if augment.fireTimeGroup.additive then
      statModifiers.fireTimeGroup.additive = (statModifiers.fireTimeGroup.additive or 0) + augment.fireTime.additive
    end

    if augment.fireTimeGroup.multiplicative then
      statModifiers.fireTimeGroup.multiplicative = (statModifiers.fireTimeGroup.multiplicative or 1) +
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

    if statModifiers.fireTimeGroup.additive then
      local isSemi = output.config.semi
      if input.parameters.semi ~= nil then
        isSemi = input.parameters.semi
      end

      local distributedStats = (isSemi and newChargeTime > 0) and 2 or 1

      fireTimeAdd = statModifiers.fireTimeGroup.additive / distributedStats

      chargeAdd = fireTimeAdd
      if newChargeTime > 0 and not isSemi then
        chargeAdd = statModifiers.fireTimeGroup.additive
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
          getModifiedStat(newCycleTime[1], fireTimeAdd, statModifiers.fireTimeGroup.multiplicative, true)),
                      math.max(minFireTime,
          getModifiedStat(newCycleTime[2], fireTimeAdd, statModifiers.fireTimeGroup.multiplicative, true))}
    else
      newCycleTime = math.max(minFireTime,
          getModifiedStat(newCycleTime, fireTimeAdd, statModifiers.fireTimeGroup.multiplicative, true))
    end

    newCockTime = math.max(minFireTime,
        getModifiedStat(newCockTime, fireTimeAdd, statModifiers.fireTimeGroup.multiplicative, true))
    newFireTime = math.max(minFireTime,
        getModifiedStat(newFireTime, fireTimeAdd, statModifiers.fireTimeGroup.multiplicative, true))

    if newChargeTime > 0 then
      newChargeTime = math.max(0, getModifiedStat(newChargeTime, chargeAdd, statModifiers.fireTimeGroup.multiplicative, true))
    end
    if newOverchargeTime > 0 then
      newOverchargeTime = math.max(0, getModifiedStat(newOverchargeTime, overchargeAdd,
          statModifiers.fireTimeGroup.multiplicative, true))
    end

    newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
      cockTime = newCockTime,
      cycleTime = newCycleTime,
      chargeTime = newChargeTime,
      overchargeTime = newOverchargeTime,
      fireTime = newFireTime
    })

    -- to be REALLY safe, nullify fireTime modification after processing
    augment.fireTimeGroup = nil

  end

  -- Alter level
  if augment.level then
    output:setInstanceValue("level", math.min(10, (input.parameters.level or output.config.level) + augment.level))
    augment.level = nil
  end

  -- SECTION: GENERAL CHANGES

  -- Recalculates final stat set in the primaryAbility parameters.
  -- @param stat: {StatGroup|StatAlias|Stat}<string>
  -- * can be the name of a group of stats, an alias of a stat, or the stat itself
  local recalculateStat = function(stat)

    stat = statAlias[stat] or stat
    if not (statList[stat] or isStatGroup[stat]) then return newPrimaryAbility end

    -- to merge onto newPrimaryAbility
    local primaryAbilityMod = {}

    -- group
    if isStatGroup[stat] or isGroupMember[stat] then
      
      local group = isStatGroup[stat] and stat or statGroup[stat]

      -- begin group recalculation
      for substat, substatBaseValue in pairs(statModifiers[group].base) do
        -- get member stat entry modifications
        local substatAdditive = (statModifiers[substat] or {additive=0}).additive
        local substatMultiplicative = (statModifiers[substat] or {multiplicative=0}).multiplicative
        -- apply group modification + member modification
        primaryAbilityMod[substat] = getModifiedStat(
          substatBaseValue,
          statModifiers[group].additive or 0 + substatAdditive,
          statModifiers[group].multiplicative or 0 + substatMultiplicative,
          isBadStat[substat],
          isIntegerStat[substat],
          statBounds[substat]
        )
      end

    -- individual
    else
      -- initialize
      statModifiers[stat] = statModifiers[stat] or {
        base = baseStat(stat),
        additive = 0,
        multiplicative = 1
      }
      
      -- recalculate
      primaryAbilityMod[stat] = getModifiedStat(
        statModifiers[stat].base,
        statModifiers[stat].additive,
        statModifiers[stat].multiplicative,
        isBadStat[stat],
        isIntegerStat[stat],
        statBounds[stat]
      )
    end

    -- apply recalculation
    newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, primaryAbilityMod)

    return newPrimaryAbility

  end
  
  -- Updates the statModifier entry of a `stat`.
  -- @param stat: {StatGroup|StatAlias|Stat}<string>
  -- * can be the name of a group of stats, an alias of a stat, or the stat itself
  -- @param rebase: number
  -- * the new base value of `stat`.
  -- * does not apply to groups
  -- @param rebaseMult: number
  -- * factor by which the base value of `stat` will be multiplied.
  -- * does not apply to groups
  -- @param additive: number
  -- @param multiplicative: number
  local updateStatModifiers = function(stat, rebase, rebaseMult, additive, multiplicative)

    stat = statAlias[stat] or stat
    if not (statList[stat] or isStatGroup[stat]) then return statModifiers end

    local group = isStatGroup[stat] and stat or statGroup[stat]
    
    -- initialize group entry
    if group then
      statModifiers[group] = statModifiers[group] or {
        base = {},
        additive = 0,
        multiplicative = 1
      }
      for _, substat in ipairs(groupStats[group]) do
        statModifiers[group].base[substat] = baseStat(substat)
      end
    end

    -- initialize member/individual entry
    if not isStatGroup[stat] then

      if isGroupMember[stat] then
        statModifiers[stat] = statModifiers[stat] or {
          additive = 0,
          multiplicative = 0
        }
      else
        statModifiers[stat] = statModifiers[stat] or {
          base = baseStat(stat),
          additive = 0,
          multiplicative = 1
        }
      end

      -- rebase, rebaseMult on member/individual stats only
      if group then
        statModifiers[group].base[stat] = (rebase or baseStat(stat)) * (rebaseMult or 1)
      else
        statModifiers[stat].base = (rebase or baseStat(stat)) * (rebaseMult or 1)
      end

    end

    -- additive, multiplicative
    statModifiers[group or stat].additive =
      (statModifiers[group or stat].additive or 0) + (additive or 0)
    statModifiers[group or stat].multiplicative =
      (statModifiers[group or stat].multiplicative or (isGroupMember[stat] and 0 or 1)) + (multiplicative or 0)
    
    newPrimaryAbility = recalculateStat(stat)

    return statModifiers, newPrimaryAbility

  end

  -- Actual general case handling
  for stat, op in pairs(augment) do

    local actualStat = statAlias[stat] or stat

    local restricted = false
    if isGroupMember[actualStat] then
      restricted = isRestrictedGroup[statGroup[actualStat]]
    elseif isStatGroup[actualStat] then
      restricted = isRestrictedGroup[actualStat]
    else
      restricted = isRestrictedStat[actualStat]
    end
    
    if restricted then
      -- restricting stats and statGroups only allow rebasing
      -- and rebase multiplication due to special cases
      -- e.g. fireTime is calculated according to weapon parameters
      statModifiers, newPrimaryAbility = updateStatModifiers(stat, op.rebase, op.rebaseMult, nil, nil) --> will recalculateStat
    else
      statModifiers, newPrimaryAbility = updateStatModifiers(stat, op.rebase, op.rebaseMult, op.additive, op.multiplicative) --> will recalculateStat
    end

    -- after doing operation, nullify augment.stat
    augment[stat] = nil

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
