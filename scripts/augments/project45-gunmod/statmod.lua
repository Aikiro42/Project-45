require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"

function apply(output, augment)

  local input = output:descriptor()
  local modInfo = output:instanceValue("project45GunModInfo")
  
  if augment then

    
    local genericStats = {
      "baseDamage",
      "maxAmmo",
      "bulletsPerReload",
      "reloadCost",
      "critChance",
      "critDamageMult",
      "ammoPerShot",
      "ammoConsumeChance",
      "inaccuracy",
      
      "multishot",
      "projectileCount",
      "spread",

      "chargeDamageMult",
      "perfectChargeDamageMult",
      "dischargeDelayTime",
      
      "movementSpeedFactor",
      "jumpHeightFactor",


      -- TODO: make special case for recoil
      --[[
      "recoilAmount",
      --]]

      -- TODO: make special case for ergonomics
      --[[
      "recoverTime",
      "recoverDelay"
      --]]

    }

    -- stat translations from stat to augment
    local statTranslations = {
      critDamageMult = "critDamage"
    }

    local integerStats = set.new({
      "maxAmmo",
      "bulletsPerReload",
      "ammoPerShot",
      "projectileCount"
    })

    -- the higher these stats, the lesser the appeal
    local negativeStats = set.new({
      "reloadCost",
      "ammoConsumeChance",
      "inaccuracy",
    })

    local statList = input.parameters.statList or {nil} -- retrieve stat mods

    local configParameterStat = function(stat, default)
      if output.parameters.primaryAbility[stat] ~= nil then
        return output.parameters.primaryAbility[stat]
      elseif output.config.primaryAbility[stat] ~= nil then
        return output.config.primaryAbility[stat]
      else
        return default
      end
    end

    -- MOD INSTALLATION PROCESS

    -- prepare to alter stats and the primary ability in general
    local newPrimaryAbility = {}
    
    -- local statModifiers = input.parameters.statModifiers or {}
    local statModifiers = output:instanceValue("statModifiers", {})
    
    -- SECTION: Special Stats

    local ammoStats = {"multishot", "projectileCount", "spread"}
    for _, ammoStat in ipairs(ammoStats) do
      statModifiers[ammoStat] = statModifiers[ammoStat] or {
        base = configParameterStat(ammoStat, 1)
      }

      -- rebase and recalculate ammo stat if changed
      if statModifiers[ammoStat].base ~= configParameterStat(ammoStat, 1) then
        statModifiers[ammoStat].base = configParameterStat(ammoStat, 1)
        local ammoStatTable = {}
        ammoStatTable[ammoStat] = moddedStat(
          statModifiers[ammoStat].base,
          statModifiers[ammoStat].additive or 0,
          statModifiers[ammoStat].multiplicative or 1,
          negativeStats[ammoStat],
          integerStats[ammoStat]
        )
      end
    end

    -- Alter Max Ammo
    if augment.maxAmmo then
      -- if augment modifies max ammo (only)
      -- and gun reloads entire ammo capacity
      -- modify bulletsPerReload the same amount the same way
      
      statModifiers.maxAmmo = statModifiers.maxAmmo or {
        base = configParameterStat("maxAmmo", 1) -- 1 is safest stat value
      }
      statModifiers.bulletsPerReload = statModifiers.bulletsPerReload or {
        base = configParameterStat("bulletsPerReload", statModifiers.maxAmmo.base) -- 1 is safest stat value
      }

      if statModifiers.bulletsPerReload.base >= statModifiers.maxAmmo.base and not augment.bulletsPerReload then
          augment.bulletsPerReload = augment.maxAmmo
      end

    end


    -- Alter general Fire Rate
    if augment.fireTime then

      statModifiers.fireTime = statModifiers.fireTime or {
        base = {
          cockTime = configParameterStat("cockTime"),
          cycleTime = configParameterStat("cycleTime"),
          midCockDelay = configParameterStat("midCockDelay", 0),
          chargeTime = configParameterStat("chargeTime"),
          overchargeTime = configParameterStat("overchargeTime"),
          fireTime = configParameterStat("fireTime")
        }
      }

      local newCockTime = statModifiers.fireTime.base.cockTime
      local newMidCockDelay = statModifiers.fireTime.base.midCockDelay
      local newCycleTime = statModifiers.fireTime.base.cycleTime
      local newFireTime = statModifiers.fireTime.base.fireTime

      local newChargeTime = statModifiers.fireTime.base.chargeTime
      local newOverchargeTime = statModifiers.fireTime.base.overchargeTime

      local minFireTime = math.min(0.001, type(newCycleTime) == "table" and newCycleTime[1] or newCycleTime,
          newCockTime, newFireTime)

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

      -- sb.logInfo(newOverchargeTime)
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
        cockTime = newCockTime,
        cycleTime = newCycleTime,
        chargeTime = newChargeTime,
        overchargeTime = newOverchargeTime,
        fireTime = newFireTime
      })

    end

    if augment.level then
      output:setInstanceValue("level", math.min(10, (input.parameters.level or output.config.level) + augment.level))
    end

    -- SECTION: GENERIC STATS; stats that are straightforward to change
    
    for _, genericStat in ipairs(genericStats) do

      local augmentStat = statTranslations[genericStat] or genericStat

      if augment[augmentStat] then
        statModifiers[genericStat] = statModifiers[genericStat] or {
          base = configParameterStat(genericStat, 1) -- 1 is safest stat value
        }
        if augment[augmentStat].additive then
          statModifiers[genericStat].additive = (statModifiers[genericStat].additive or 0) + augment[augmentStat].additive
        end
        if augment[augmentStat].multiplicative then
          statModifiers[genericStat].multiplicative = (statModifiers[genericStat].multiplicative or 1) + augment[augmentStat].multiplicative
        end

        local statModTable = {}
        statModTable[genericStat] = moddedStat(
          statModifiers[genericStat].base,
          statModifiers[genericStat].additive,
          statModifiers[genericStat].multiplicative,
          negativeStats[genericStat],
          integerStats[genericStat]
        )
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, statModTable)
      end
    end

    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(input.parameters.primaryAbility, newPrimaryAbility))
    output:setInstanceValue("statModifiers", statModifiers)

    return output

  end
end

function moddedStat(base, additive, multiplicative, isDiv, isInt)

  additive = additive or 0
  multiplicative = multiplicative or 1
  local result = 0
  if isDiv then
    result = (base / multiplicative) + additive
  else
    result = base * multiplicative + additive
  end

  if isInt then
    return math.floor(result)
  end
  return result

end
