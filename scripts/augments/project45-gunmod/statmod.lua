require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/formulas.lua"

function apply(output, augment)

  local input = output:descriptor()
  local modInfo = output:instanceValue("project45GunModInfo")

  local configParameterStat = function(stat, default)
    return output:instanceValue("primaryAbility", {})[stat] or default
  end

  local statModifiers = output:instanceValue("statModifiers", {})

  local statConfig = root.assetJson("/configs/project45/project45_generalstat.config")

  local newPrimaryAbility = {}

  -- stat lists composed of string-defaultValue pairs
  local statList = statConfig.statDefaults or {}

  -- stat flags
  local isRestrictedStat = set.new(statConfig.restrictedStats or {})
  local isConfigStat = set.new(statConfig.configStats or {})
  local isRestrictedGroup = set.new(statConfig.restrictedGroups or {})
  local isIntegerStat = set.new(statConfig.integerStats or {})
  local isBadStat = set.new(statConfig.badStats or {})
  local isBadGroup = set.new(statConfig.badGroups or {})
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
  -- 1. from the respective `statModifiers` entry of the stat (either in the base table of a group or the base field of an individual entry)
  -- 2. from the weapon's config
  -- 3. from the `statDefaults` dictionary in `statmod.config`
  -- @param stat: string
  -- * can either be a member or individual stat/alias
  -- @param getRaw: boolean
  -- * whether the stat skips the stat config checks
  -- and just attempts to get the value straight from
  -- the weapon's parameter or config.
  -- This is useful for non-numerical stats like `quickReloadTimeframe`
  local baseStat = function(stat, getRaw)

    if getRaw then
      local configPrimaryAbility = sb.jsonMerge(output.config.primaryAbility, output.parameters.primaryAbility)
      return configPrimaryAbility[stat]
    end

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

    if saved then return saved end

    if not statList[stat] then
      sb.logError("(statmod.lua) UNREGISTERED STAT QUERIED")
    end

    local configPrimaryAbility = sb.jsonMerge(output.config.primaryAbility, output.parameters.primaryAbility)

    return configPrimaryAbility[stat] or statList[stat]

  end

  -- Recalculates the final base value of a given stat.
  -- Also initializes the individual/member entry of a stat, particularly its baseOrig and baseMult fields.
  -- WARNING: Must be called before any stat calculation
  local updateBase = function(stat, rebase, rebaseMult)
    if isStatGroup[stat] then
      sb.logError("Attempted to recalculate base of group.")
      return nil
    end
    -- initalize stat entry
    statModifiers[stat] = statModifiers[stat] or {
      baseOrig = baseStat(stat),
      baseMult = 1,
      additive = 0,
      multiplicative = statGroup[stat] and 0 or 1
    }
    statModifiers[stat].baseOrig = rebase or statModifiers[stat].baseOrig or baseStat(stat)
    statModifiers[stat].baseMult = (statModifiers[stat].baseMult or 1) * (rebaseMult or 1)
    
    local recalculatedBase = statModifiers[stat].baseOrig * statModifiers[stat].baseMult
    if statGroup[stat] then
      -- if stat is member, replace base value in group
      statModifiers[statGroup[stat]].base[stat] = recalculatedBase
    else
      -- if stat is individual, replace its base value
      statModifiers[stat].base = recalculatedBase
    end

    -- return recalculated value just in case it's needed
    return recalculatedBase
  end

  -- SECTION: SPECIAL STAT CASES

  -- General handling of Max Ammo
  if augment.maxAmmo then

    statModifiers.maxAmmo = statModifiers.maxAmmo or {
      base = baseStat("maxAmmo"),
      baseOrig = baseStat("maxAmmo"),
      baseMult = 1,
      additive = 0,
      multiplicative = 1
    }
    statModifiers.bulletsPerReload = statModifiers.bulletsPerReload or {
      base = baseStat("bulletsPerReload"),
      baseOrig = baseStat("bulletsPerReload"),
      baseMult = 1,
      additive = 0,
      multiplicative = 1
    }

    if statModifiers.bulletsPerReload.base >= statModifiers.maxAmmo.base and not augment.bulletsPerReload then
      augment.bulletsPerReload = augment.maxAmmo
    end

  end
  
  -- Per-bullet reload to full reload conversion
  if augment.bulletsPerReload and augment.bulletsPerReload.rebase then
    if string.lower(augment.bulletsPerReload.rebase) == "full" then
      -- it's quite complicated and slow to prematurely determine final max ammo,
      -- so we set it to a very large value
      -- the case where bulletsPerReload > maxAmmo is corrected by the weaponability anyway
      augment.bulletsPerReload.rebase = 999999
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

      statModifiers.fireTimeGroup.base[fireTimeGroupStat] = statModifiers.fireTimeGroup.base[fireTimeGroupStat] or baseStat(fireTimeGroupStat)
      
      updateBase(fireTimeGroupStat, augment[fireTimeGroupStat].rebase, augment[fireTimeGroupStat].rebaseMult)
        
      -- prompt recalculation
      augment.fireTimeGroup = augment.fireTimeGroup or {}

      -- clear entry to prevent general case from covering this
      augment[fireTimeGroupStat] = nil
  
    end  
  end

  
  -- Alter general Reload Time
  if augment.reloadTimeGroup then
    -- initialize reloadTimeGroup if necessary
    statModifiers.reloadTimeGroup = statModifiers.reloadTimeGroup or {
      base = {},
      additive = 0,
      multiplicative = 1
    }

    -- reobtain the base stats to do recalculations
    for _, reloadTimeStat in ipairs(groupStats.reloadTimeGroup) do
      statModifiers.reloadTimeGroup.base[reloadTimeStat] = baseStat(reloadTimeStat)
    end

    local newCockTime = statModifiers.reloadTimeGroup.base.cockTime
    local newMidCockDelay = statModifiers.reloadTimeGroup.base.midCockDelay
    local newReloadTime = statModifiers.reloadTimeGroup.base.reloadTime

    -- obtain the quick reload parameters
    local QRParams = baseStat("quickReloadParameters", true)
      or formulas.quickReloadParameters(newReloadTime, baseStat("quickReloadTimeframe", true) or {0.5, 0.6, 0.7, 0.8})

    local minReloadTime = 0.5
    local minCockTime = 0.001

    if augment.reloadTimeGroup.additive then
      statModifiers.reloadTimeGroup.additive =
          (statModifiers.reloadTimeGroup.additive or 0)
        + augment.reloadTimeGroup.additive
    end

    if augment.reloadTimeGroup.multiplicative then
      statModifiers.reloadTimeGroup.multiplicative =
          (statModifiers.reloadTimeGroup.multiplicative or 1)
        + augment.reloadTimeGroup.multiplicative
    end

    local reloadTimeAdd = statModifiers.reloadTimeGroup.additive

    -- modify reload time and get how much the reload window should increase
    newReloadTime = math.max(minReloadTime,
      getModifiedStat(newReloadTime, reloadTimeAdd, statModifiers.reloadTimeGroup.multiplicative, true))

    -- modify cock time
    newCockTime = math.max(minCockTime,
      getModifiedStat(newCockTime, reloadTimeAdd, statModifiers.reloadTimeGroup.multiplicative, true))
    newMidCockDelay = math.max(0,
      getModifiedStat(newMidCockDelay, reloadTimeAdd, statModifiers.reloadTimeGroup.multiplicative, true))

    -- apply modded values to primary ability
    newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
      quickReloadParameters = QRParams,
      reloadTime = newReloadTime,
      cockTime = newCockTime,
      midCockDelay = newMidCockDelay
    })

    -- to be REALLY safe,
    -- nullify fireTime modification after processing
    -- to prevent the general stat applicators
    -- to process this group at all
    augment.reloadTimeGroup = nil

  end

  -- Alter general Fire Time
  if augment.fireTimeGroup then

    -- initialize fireTimeGroup if necessary
    statModifiers.fireTimeGroup = statModifiers.fireTimeGroup or {
      base = {},
      additive = 0,
      multiplicative = 1
    }

    -- reobtain the base stats to do recalculations
    for _, fireTimeStat in ipairs(groupStats.fireTimeGroup) do
      statModifiers.fireTimeGroup.base[fireTimeStat] = baseStat(fireTimeStat)
    end

    -- local newCockTime = statModifiers.fireTimeGroup.base.cockTime
    -- local newMidCockDelay = statModifiers.fireTimeGroup.base.midCockDelay
    local newCycleTime = statModifiers.fireTimeGroup.base.cycleTime
    local newFireTime = statModifiers.fireTimeGroup.base.fireTime

    local newChargeTime = statModifiers.fireTimeGroup.base.chargeTime
    local newOverchargeTime = statModifiers.fireTimeGroup.base.overchargeTime

    --[[
    local minFireTime = math.min(
      0.001,
      type(newCycleTime) == "table" and newCycleTime[1] or newCycleTime,
      newCockTime,
      newFireTime
    )
    --]]
    local minFireTime = 0.001

    if augment.fireTimeGroup.additive then
      statModifiers.fireTimeGroup.additive = (statModifiers.fireTimeGroup.additive or 0) + augment.fireTimeGroup.additive
    end

    if augment.fireTimeGroup.multiplicative then
      statModifiers.fireTimeGroup.multiplicative = (statModifiers.fireTimeGroup.multiplicative or 1) +
                                                  augment.fireTimeGroup.multiplicative
    end

    -- apply fireTime modifiers

    local fireTimeAdd, chargeAdd, overchargeAdd
    -- NOTE: I know this is bad practice,
    -- but the above variables being possibly nil is okay
    -- because the function they're used in (getModifiedStat())
    -- handles the case wherein they're nil.
    -- Change this implementation if it actually
    -- affects performance negatively.

    if statModifiers.fireTimeGroup.additive then
      
      fireTimeAdd = statModifiers.fireTimeGroup.additive
      chargeAdd = statModifiers.fireTimeGroup.additive

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

    -- modify trigger time
    newFireTime = math.max(minFireTime,
      getModifiedStat(newFireTime, fireTimeAdd, statModifiers.fireTimeGroup.multiplicative, true))
    
    -- modify cock time
    --[[
    newCockTime = math.max(minFireTime,
      getModifiedStat(newCockTime, fireTimeAdd, statModifiers.fireTimeGroup.multiplicative, true))
    newMidCockDelay = math.max(minFireTime,
      getModifiedStat(newMidCockDelay, fireTimeAdd, statModifiers.fireTimeGroup.multiplicative, true))
    --]]

    -- modify charge time
    if newChargeTime > 0 then
      newChargeTime = math.max(0, getModifiedStat(newChargeTime, chargeAdd, statModifiers.fireTimeGroup.multiplicative, true))
    end
    if newOverchargeTime > 0 then
      newOverchargeTime = math.max(0, getModifiedStat(newOverchargeTime, overchargeAdd,
          statModifiers.fireTimeGroup.multiplicative, true))
    end

    -- apply modded values to primary ability
    newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {

      -- cockTime = newCockTime,
      -- midCockDelay = newMidCockDelay,

      cycleTime = newCycleTime,
      chargeTime = newChargeTime,
      overchargeTime = newOverchargeTime,
      fireTime = newFireTime,
    })

    -- to be REALLY safe,
    -- nullify fireTime modification after processing
    -- to prevent the general stat applicators
    -- to process this group at all
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
          (statModifiers[group].additive or 0) + substatAdditive,
          (statModifiers[group].multiplicative or 0) + substatMultiplicative,
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
        baseOrig = baseStat(stat),
        baseMult = 1,
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
    
    -- if provided stat is actually a group, initialize group entry
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

    -- otherwise, initialize member/individual entry of given stat
    if not isStatGroup[stat] then

      if isGroupMember[stat] then
        statModifiers[stat] = statModifiers[stat] or {
          baseOrig = baseStat(stat),
          baseMult = 1,
          additive = 0,
          multiplicative = 0
        }
      else
        statModifiers[stat] = statModifiers[stat] or {
          base = baseStat(stat),
          baseOrig = baseStat(stat),
          baseMult = 1,
          additive = 0,
          multiplicative = 1
        }
      end

      updateBase(stat, rebase, rebaseMult)

    end

    -- additive, multiplicative
    statModifiers[group or stat].additive =
      (statModifiers[group or stat].additive or 0) + (additive or 0)
    statModifiers[group or stat].multiplicative =
      (statModifiers[group or stat].multiplicative or (isGroupMember[stat] and 0 or 1)) + (multiplicative or 0)
    
    newPrimaryAbility = recalculateStat(stat)

    return statModifiers, newPrimaryAbility

  end

  -- special fields

  local specFields = {
    randomStatParams = true,
    pureStatMod = true,
    stackLimit = true
  }

  -- Actual general case handling
  for stat, op in pairs(augment) do

    if not specFields[stat] then

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
        -- FIXME: cast-local-type
---@diagnostic disable-next-line: cast-local-type
        statModifiers, newPrimaryAbility = updateStatModifiers(stat, op.rebase, op.rebaseMult, nil, nil) --> will recalculateStat
      else
---@diagnostic disable-next-line: cast-local-type
        statModifiers, newPrimaryAbility = updateStatModifiers(stat, op.rebase, op.rebaseMult, op.additive, op.multiplicative) --> will recalculateStat
      end

      -- after doing operation, nullify augment.stat
      augment[stat] = nil
    
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
