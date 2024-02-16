require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"

function apply(input, override, augment)

  -- do not install mod if the thing this mod is applied to isn't a gun
    local output = Item.new(input)
    local modInfo = sb.jsonMerge(output.config.project45GunModInfo, input.parameters.project45GunModInfo)
    if not modInfo then return end

  local augment = augment or config.getParameter("augment")
  
  -- if augment field exists, do something
  if augment then

    local upgradeCost = augment.upgradeCost or 1
    local statList = input.parameters.statList or {nil} -- retrieve stat mods
    local upgradeCount = input.parameters.upgradeCount or 0
    local upgradeCapacity = modInfo.upgradeCapacity or -1

    local configParameterStat = function(stat, default)
        if output.parameters.primaryAbility[stat] ~= nil then
            return output.parameters.primaryAbility[stat]
        elseif output.config.primaryAbility[stat] ~= nil then
            return output.config.primaryAbility[stat]
        else
            return default
        end
    end
    
    -- MOD INSTALLATION GATES

    if not override then

        -- deny installation if upgrade capacity not enough
        if upgradeCapacity > -1 and upgradeCount + upgradeCost > upgradeCapacity then
            sb.logError("(statmod.lua) Stat mod application failed: Not Enough Upgrade Capacity")
            return gunmodHelper.addMessage(input, "Not Enough Upgrade Capacity")
        end

        -- deny installation if stat mod upgrades level
        -- and level of weapon is 10
        if augment.level and (input.parameters.level or 1) >= 10 then
            sb.logError("(statmod.lua) Stat mod application failed: max level reached.")
            return gunmodHelper.addMessage(input, "Max level reached")
        end
    
    end

    -- MOD INSTALLATION PROCESS

    -- prepare to alter stats and the primary ability in general
    local newPrimaryAbility = {}

    local statModifiers = input.parameters.statModifiers or {}

    -- Alter Damage Per Shot
    if augment.baseDamage then

        statModifiers.baseDamage = statModifiers.baseDamage or {base = configParameterStat("baseDamage")}
                
        if augment.baseDamage.additive then
            statModifiers.baseDamage.additive =
                (statModifiers.baseDamage.additive or 0) + augment.baseDamage.additive
        end

        if augment.baseDamage.multiplicative then
            statModifiers.baseDamage.multiplicative =
                (statModifiers.baseDamage.multiplicative or 1) + augment.baseDamage.multiplicative
        end
        
        -- apply baseDamage modifiers
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility,
            {
                baseDamage = moddedStat(
                    statModifiers.baseDamage.base,
                    statModifiers.baseDamage.additive,
                    statModifiers.baseDamage.multiplicative
                )
            })

    end

    -- Alter general Fire Rate
    if augment.fireTime then

        statModifiers.fireTime = statModifiers.fireTime or {base = {
            cockTime = configParameterStat("cockTime"),
            cycleTime = configParameterStat("cycleTime"),
            chargeTime = configParameterStat("chargeTime"),
            overchargeTime = configParameterStat("overchargeTime"),
            fireTime = configParameterStat("fireTime")
        }}
        
        local newCockTime = statModifiers.fireTime.base.cockTime
        local newCycleTime = statModifiers.fireTime.base.cycleTime
        local newFireTime = statModifiers.fireTime.base.fireTime

        local newChargeTime = statModifiers.fireTime.base.chargeTime
        local newOverchargeTime = statModifiers.fireTime.base.overchargeTime

        local minFireTime = math.min(
            root.assetJson("/configs/project45/project45_generalconfig.config:minimumFireTime", 0.001),
            type(newCycleTime) == "table" and newCycleTime[1] or newCycleTime,
            newCockTime,
            newFireTime
        )
            
        if augment.fireTime.additive then
            statModifiers.fireTime.additive =
                (statModifiers.fireTime.additive or 0) + augment.fireTime.additive
        end

        if augment.fireTime.multiplicative then
            statModifiers.fireTime.multiplicative =
                (statModifiers.fireTime.multiplicative or 1) + augment.fireTime.multiplicative
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

            local distributedStats = (isSemi and newChargeTime > 0) and 3 or 2
            
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

        if type(newCycleTime) == "table" then
            newCycleTime = {
                math.max(minFireTime, moddedStat(
                        newCycleTime[1],
                        fireTimeAdd,
                        statModifiers.fireTime.multiplicative,
                        true
                    )
                ),
                math.max(minFireTime, moddedStat(
                        newCycleTime[2],
                        fireTimeAdd,
                        statModifiers.fireTime.multiplicative,
                        true
                    )
                )
            }
        else
            newCycleTime = math.max(minFireTime, moddedStat(
                    newCycleTime,
                    fireTimeAdd,
                    statModifiers.fireTime.multiplicative,
                    true
                )
            )
        end
    
        newCockTime = math.max(minFireTime, moddedStat(
                newCockTime,
                fireTimeAdd,
                statModifiers.fireTime.multiplicative,
                true
            )
        )
        newFireTime = math.max(minFireTime, moddedStat(
                newFireTime,
                fireTimeAdd,
                statModifiers.fireTime.multiplicative,
                true
            )
        )
        
        newChargeTime = math.max(0, moddedStat(
                newChargeTime,
                chargeAdd,
                statModifiers.fireTime.multiplicative,
                true
            )
        )

        newOverchargeTime = math.max(0, moddedStat(
                newOverchargeTime,
                overchargeAdd,
                statModifiers.fireTime.multiplicative,
                true
            )
        )


        -- sb.logInfo(newOverchargeTime)
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
            cockTime = newCockTime,
            cycleTime = newCycleTime,
            chargeTime = newChargeTime,
            overchargeTime = newOverchargeTime,
            fireTime = newFireTime
        })

    end

    -- modify reload cost
    if augment.reloadCost then

        statModifiers.reloadCost = statModifiers.reloadCost or {base = configParameterStat("reloadCost")}

        if augment.reloadCost.additive then
            statModifiers.reloadCost.additive =
                (statModifiers.reloadCost.additive or 0) + augment.reloadCost.additive
        end

        if augment.reloadCost.multiplicative then
            statModifiers.reloadCost.multiplicative =
                (statModifiers.reloadCost.multiplicative or 1) + augment.reloadCost.multiplicative
        end
        
        -- apply reloadCost modifiers
        local newReloadCost = math.max(0, moddedStat(
                statModifiers.reloadCost.base,
                statModifiers.reloadCost.additive,
                statModifiers.reloadCost.multiplicative,
                true
            )
        )
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {reloadCost = newReloadCost})

    end
    
    -- modify crit chance
    if augment.critChance then
        
        statModifiers.critChance = statModifiers.critChance or {base=configParameterStat("critChance")}

        if augment.critChance.additive then
            statModifiers.critChance.additive =
                (statModifiers.critChance.additive or 0) + augment.critChance.additive
        end

        if augment.critChance.multiplicative then
            statModifiers.critChance.multiplicative =
                (statModifiers.critChance.multiplicative or 1) + augment.critChance.multiplicative
        end
        
        -- apply critChance modifiers
        local newCritChance = moddedStat(
            statModifiers.critChance.base,
            statModifiers.critChance.additive,
            statModifiers.critChance.multiplicative
        )
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critChance = newCritChance})
    end

    -- modify critDamage
    if augment.critDamage then
        
        statModifiers.critDamage = statModifiers.critDamage or {base=configParameterStat("critDamageMult")}

        if augment.critDamage.additive then
            statModifiers.critDamage.additive =
                (statModifiers.critDamage.additive or 0) + augment.critDamage.additive
        end
        
        if augment.critDamage.multiplicative then
            statModifiers.critDamage.multiplicative =
                (statModifiers.critDamage.multiplicative or 1) + augment.critDamage.multiplicative
        end
        
        -- apply critDamageMult modifiers
        local newCritDamage = moddedStat(
            statModifiers.critDamage.base,
            statModifiers.critDamage.additive,
            statModifiers.critDamage.multiplicative
        )
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critDamageMult = newCritDamage})
    end

    if augment.level then
        output:setInstanceValue("level", math.min(10, (input.parameters.level or output.config.level) + augment.level))
    end

    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(input.parameters.primaryAbility, newPrimaryAbility))
    output:setInstanceValue("statModifiers", statModifiers)

    if not override then
        -- count stat if not wildcard
        if not augment.randomStats then
            statList[config.getParameter("itemName")] = (statList[config.getParameter("itemName")] or 0) + 1
        else
            local retrievedSeed = config.getParameter("seed")
            statList.wildcards = statList.wildcards or {}
            table.insert(statList.wildcards, retrievedSeed)
        end
        output:setInstanceValue("statList", statList)
        output:setInstanceValue("upgradeCount", upgradeCount + upgradeCost)

        output:setInstanceValue("isModded", true)
    end

    return output:descriptor(), 1
  
  end
end

function moddedStat(base, additive, multiplicative, isDiv)
    
    additive = additive or 0
    multiplicative = multiplicative or 1

    if isDiv then
        return (base / multiplicative) + additive
    end

    return base * multiplicative + additive

end