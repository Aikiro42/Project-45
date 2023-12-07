require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

function apply(input)

  -- do not install mod if the thing this mod is applied to isn't a gun
  local modInfo = input.parameters.project45GunModInfo
  if not modInfo then return end

  local augment = config.getParameter("augment")
  local output = Item.new(input)
  
  -- if augment field exists, do something
  if augment then

    local statList = input.parameters.statList or {nil} -- retrieve stat mods
    local statModCount = input.parameters.statModCount or 0
    local statModCountMax = modInfo.statModCountMax or -1
    
    -- MOD INSTALLATION GATES

    local modExceptions = modInfo.modExceptions or {}
    modExceptions.accept = modExceptions.accept or {}
    modExceptions.deny = modExceptions.deny or {}

    -- check if stat mod is particularly denied
    local denied = set.new(modExceptions.deny)
    if denied[config.getParameter("itemName")] then
      sb.logError("(statmod.lua) Stat mod application failed: gun does not accept this specific stat mod")
      return gunmodHelper.addMessage(input, "Incompatible stat mod: " .. config.getParameter("shortdescription"))
    end

    -- If the max number of stat mods that can be installed is specified (i.e. non-negative number)
    -- and the number of mods installed already reached that cap
    -- do not apply stat mod
    if statModCountMax > -1 and statModCount >= statModCountMax then
        sb.logError("(statmod.lua) Stat mod application failed: max number of stat mods have been installed")
        return gunmodHelper.addMessage(input, "Max stat mod capacity reached")
    end

    -- MOD INSTALLATION PROCESS

    -- prepare to alter stats and the primary ability in general
    local newPrimaryAbility = {}

    local statModifiers = input.parameters.statModifiers or {}

    -- Alter Damage Per Shot
    if augment.baseDamage then

        statModifiers.baseDamage = statModifiers.baseDamage or {base = output.config.primaryAbility.baseDamage}
        
        if augment.baseDamage.additive then
            statModifiers.baseDamage.additive =
                (statModifiers.baseDamage.additive or 0) + augment.baseDamage.additive

        elseif augment.baseDamage.multiplicative then
            statModifiers.baseDamage.multiplicative =
                (statModifiers.baseDamage.multiplicative or 1) + augment.baseDamage.multiplicative
        
        else
            statModifiers.baseDamage.additive = statModifiers.baseDamage.additive or 0
            statModifiers.baseDamage.multiplicative = statModifiers.baseDamage.multiplicative or 1
    
        end
        
        -- apply baseDamage modifiers
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility,
            {
                baseDamage = statModifiers.baseDamage.base
                * (statModifiers.baseDamage.multiplicative or 1)
                + (statModifiers.baseDamage.additive or 0)
            })

    end

    -- Alter general Fire Rate
    if augment.fireTime then

        statModifiers.fireTime = statModifiers.fireTime or {base = {
            cockTime = output.config.primaryAbility.cockTime,
            cycleTime = output.config.primaryAbility.cycleTime,
            chargeTime = output.config.primaryAbility.chargeTime,
            overchargeTime = output.config.primaryAbility.overchargeTime,
            fireTime = output.config.primaryAbility.fireTime
        }}

        local newCockTime = statModifiers.fireTime.base.cockTime
        local newCycleTime = statModifiers.fireTime.base.cycleTime
        local newChargeTime = statModifiers.fireTime.base.chargeTime
        local newOverchargeTime = statModifiers.fireTime.base.overchargeTime
        local newFireTime = statModifiers.fireTime.base.fireTime

        local minFireTime = math.min(
            0.001, -- TODO: add default min value
            type(newCycleTime) == "table" and newCycleTime[1] or newCycleTime,
            newCockTime,
            newFireTime
        )
        
        if augment.fireTime.additive then
            statModifiers.fireTime.additive =
                (statModifiers.fireTime.additive or 0) + augment.fireTime.additive

        elseif augment.fireTime.multiplicative then
            statModifiers.fireTime.multiplicative =
                (statModifiers.fireTime.multiplicative or 1) + augment.fireTime.multiplicative
        else
            statModifiers.fireTime.additive = statModifiers.fireTime.additive or 0
            statModifiers.fireTime.multiplicative = statModifiers.fireTime.multiplicative or 1
        end

        -- apply fireTime modifiers
        if type(newCycleTime) == "table" then
            newCycleTime = {
                math.max(minFireTime, newCycleTime[1]
                    / (statModifiers.fireTime.multiplicative or 1) + (statModifiers.fireTime.additive or 0)
                ),
                math.max(minFireTime, newCycleTime[2]
                    / (statModifiers.fireTime.multiplicative or 1) + (statModifiers.fireTime.additive or 0)
                )
            }
        else
            newCycleTime = math.max(minFireTime, newCycleTime
                / (statModifiers.fireTime.multiplicative or 1) + (statModifiers.fireTime.additive or 0)
            )
        end
    
        newCockTime = math.max(minFireTime, newCockTime
            / (statModifiers.fireTime.multiplicative or 1) + (statModifiers.fireTime.additive or 0)
        )
        newFireTime = math.max(minFireTime, newFireTime
            / (statModifiers.fireTime.multiplicative or 1) + (statModifiers.fireTime.additive or 0)
        )
        newChargeTime = math.max(0, newChargeTime
            / (statModifiers.fireTime.multiplicative or 1) + (statModifiers.fireTime.additive or 0)
        )
        newOverchargeTime = math.max(0, newOverchargeTime
            / (statModifiers.fireTime.multiplicative or 1) + (statModifiers.fireTime.additive or 0)
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

        statModifiers.reloadCost = statModifiers.reloadCost or {base=output.config.primaryAbility.reloadCost}

        if augment.reloadCost.additive then
            statModifiers.reloadCost.additive =
                (statModifiers.reloadCost.additive or 0) + augment.reloadCost.additive
        
        elseif augment.reloadCost.multiplicative then
            statModifiers.reloadCost.multiplicative =
                (statModifiers.reloadCost.multiplicative or 1) + augment.reloadCost.multiplicative
        else
            statModifiers.reloadCost.additive = statModifiers.reloadCost.additive or 0
            statModifiers.reloadCost.multiplicative = statModifiers.reloadCost.multiplicative or 1
    
        end
        
        -- apply reloadCost modifiers
        local newReloadCost = statModifiers.reloadCost.base
        newReloadCost = math.max(0, newReloadCost
            / (statModifiers.reloadCost.multiplicative or 1) + (statModifiers.reloadCost.additive or 0))
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {reloadCost = newReloadCost})

    end
    
    -- modify crit chance
    if augment.critChance then
        
        statModifiers.critChance = statModifiers.critChance or {base=output.config.primaryAbility.critChance}

        if augment.critChance.additive then
            statModifiers.critChance.additive =
                (statModifiers.critChance.additive or 0) + augment.critChance.additive

        elseif augment.critChance.multiplicative then
            statModifiers.critChance.multiplicative =
                (statModifiers.critChance.multiplicative or 1) + augment.critChance.multiplicative
        else
            statModifiers.critChance.additive = statModifiers.critChance.additive or 0
            statModifiers.critChance.multiplicative = statModifiers.critChance.multiplicative or 1

        end
        
        -- apply critChance modifiers
        local newCritChance = statModifiers.critChance.base
            * (statModifiers.critChance.multiplicative or 1) + (statModifiers.critChance.additive or 0)
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critChance = newCritChance})
    end

    -- modify critDamage
    if augment.critDamage then
        statModifiers.critDamage = statModifiers.critDamage or {base=output.config.primaryAbility.critDamageMult}

        if augment.critDamage.additive then
            statModifiers.critDamage.additive =
                (statModifiers.critDamage.additive or 0) + augment.critDamage.additive

        elseif augment.critDamage.multiplicative then
            statModifiers.critDamage.multiplicative =
                (statModifiers.critDamage.multiplicative or 1) + augment.critDamage.multiplicative
        else
            statModifiers.critDamage.additive = statModifiers.critDamage.additive or 0
            statModifiers.critDamage.multiplicative = statModifiers.critDamage.multiplicative or 1
        end
        
        -- apply critDamageMult modifiers
        local newCritDamage = statModifiers.critDamage.base
            * (statModifiers.critDamage.multiplicative or 1) + (statModifiers.critDamage.additive or 0)
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critDamageMult = newCritDamage})

    end

    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(input.parameters.primaryAbility, newPrimaryAbility))
    output:setInstanceValue("statModifiers", statModifiers)

    -- count stat
    statList[config.getParameter("itemName")] = (statList[config.getParameter("itemName")] or 0) + 1
    if not statModCount then
        statModCount = 0
    else
        statModCount = statModCount + 1
    end
    
    
    output:setInstanceValue("statList", statList)
    output:setInstanceValue("statModCount", statModCount)

    output:setInstanceValue("isModded", true)

    return output:descriptor(), 1
  
  end
end
