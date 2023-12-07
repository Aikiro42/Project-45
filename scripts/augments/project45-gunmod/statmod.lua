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
    local oldPrimaryAbility = sb.jsonMerge(output.config.primaryAbility, input.parameters.primaryAbility or {})
    local newPrimaryAbility = {}

    -- Alter Damage Per Shot
    if augment.baseDamage then
        
        local newBaseDamage

        if augment.baseDamage.operation == "add" then
            newBaseDamage = oldPrimaryAbility.baseDamage + augment.baseDamage.value

        elseif augment.baseDamage.operation == "multiply" then
            newBaseDamage = oldPrimaryAbility.baseDamage * augment.baseDamage.value

        end
        
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {baseDamage = newBaseDamage})

    end

    -- Alter general Fire Rate
    if augment.fireTime then

        local newCockTime = oldPrimaryAbility.cockTime
        local newCycleTime = oldPrimaryAbility.cycleTime
        local newChargeTime = oldPrimaryAbility.chargeTime
        local newOverchargeTime = oldPrimaryAbility.overchargeTime
        local newFireTime = oldPrimaryAbility.fireTime
        
        if augment.fireTime.operation == "add" then
            
            if type(newCycleTime) == "table" then
                newCycleTime = vec2.add(newCycleTime, augment.fireTime.value)
            else
                newCycleTime = newCycleTime + augment.fireTime.value
            end
        
            newCockTime = newCockTime + augment.fireTime.value
            newChargeTime = newChargeTime + augment.fireTime.value
            newOverchargeTime = newOverchargeTime + augment.fireTime.value
            newFireTime = newFireTime + augment.fireTime.value

        elseif augment.fireTime.operation == "multiply" then
            
            if type(newCycleTime) == "table" then
                newCycleTime = vec2.mul(newCycleTime, augment.fireTime.value)
            else
                newCycleTime = newCycleTime * augment.fireTime.value
            end
        
            newCockTime = newCockTime * augment.fireTime.value
            newChargeTime = newChargeTime * augment.fireTime.value
            newOverchargeTime = newOverchargeTime * augment.fireTime.value
            newFireTime = newFireTime * augment.fireTime.value

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

    -- modify reload cost
    if augment.reloadCost then

        local newReloadCost = oldPrimaryAbility.reloadCost
        
        if augment.reloadCost.operation == "add" then
            newReloadCost = math.max(0, newReloadCost + augment.reloadCost.value)
        
        elseif augment.reloadCost.operation == "multiply" then
            newReloadCost = math.max(0, newReloadCost * augment.reloadCost.value)
        
        end

        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {reloadCost = newReloadCost})
    end
    
    -- modify crit chance
    if augment.critChance then
        
        local newCritChance = oldPrimaryAbility.critChance

        if augment.critChance.operation == "add" then
            newCritChance = newCritChance + augment.critChance.value

        elseif augment.critChance.operation == "multiply" then
            newCritChance = newCritChance * augment.critChance.value

        end

        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critChance = newCritChance})
    end

    -- modify critDamage
    if augment.critDamage then
        
        local newCritDamage = oldPrimaryAbility.critDamageMult

        if augment.critDamage.operation == "add" then
            newCritDamage = newCritDamage + augment.critDamage.value

        elseif augment.critDamage.operation == "multiply" then
            newCritDamage = newCritDamage * augment.critDamage.value

        end

        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critDamageMult = newCritDamage})
    end

    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(oldPrimaryAbility, newPrimaryAbility))

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
