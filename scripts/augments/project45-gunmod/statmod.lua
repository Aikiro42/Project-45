require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

function apply(input)

  -- do not install mod if the thing this mod is applied to isn't a gun
  if not input.parameters.acceptsGunMods then return end

  local augment = config.getParameter("augment")
  local output = Item.new(input)
  
  -- if augment field exists, do something
  if augment then

    --[[

    "augment": {
        "damagePerShot": {
            "operation": "add",
            "value": 10
        }
        "fireRate": {
            "operation": "multiply",
            "value": 0.2
        }
    }

    --]]

    local statList = input.parameters.statList or {nil} -- retrieve stat mods

    -- MOD INSTALLATION PROCESS

    -- prepare to alter stats and the primary ability in general
    local oldPrimaryAbility = output.config.primaryAbility or {}
    local newPrimaryAbility = input.parameters.primaryAbility or {}

    -- Alter Damage Per Shot
    if augment.damagePerShot then
        
        local newBaseDamage

        if augment.damagePerShot.operation == "add" then
            newBaseDamage = oldPrimaryAbility.baseDamage + augment.damagePerShot.value

        elseif augment.damagePerShot.operation == "multiply" then
            newBaseDamage = oldPrimaryAbility.baseDamage * augment.damagePerShot.value

        end
        
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {baseDamage = newBaseDamage})

    end

    -- Alter general Fire Rate
    if augment.fireRate then
    
        local newCycleTime = oldPrimaryAbility.cycleTime
        local newChargeTime = oldPrimaryAbility.chargeTime
        local newOverchargeTime = oldPrimaryAbility.overchargeTime
        local newFireTime = oldPrimaryAbility.fireTime
        
        if augment.fireRate.operation == "add" then
            
            if type(newCycleTime) == "table" then
                newCycleTime = vec2.add(newCycleTime, augment.fireRate.value)
            else
                newCycleTime = newCycleTime + augment.fireRate.value
            end
        
            newChargeTime = newChargeTime + augment.fireRate.value
            newOverchargeTime = newOverchargeTime + augment.fireRate.value
            newFireTime = newFireTime + augment.fireRate.value

        elseif augment.fireRate.operation == "multiply" then
            
            if type(newCycleTime) == "table" then
                newCycleTime = vec2.mul(newCycleTime, augment.fireRate.value)
            else
                newCycleTime = newCycleTime * augment.fireRate.value
            end
        
            newChargeTime = newChargeTime * augment.fireRate.value
            newOverchargeTime = newOverchargeTime * augment.fireRate.value
            newFireTime = newFireTime * augment.fireRate.value

        end

        -- sb.logInfo(newOverchargeTime)

        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
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
            newReloadCost = newReloadCost + augment.reloadCost.value
        
        elseif augment.reloadCost.operation == "multiply" then
            newReloadCost = newReloadCost * augment.reloadCost.value
        
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
    if augment.critDamageMult then
      local newCritDamage = math.min(oldPrimaryAbility.critDamageMult * augment.critDamageMult, 10)
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critDamageMult = newCritDamage})
    end

    if augment.critDamage then
        
        local newCritDamage = oldPrimaryAbility.critDamageMult

        if augment.critChance.operation == "add" then
            newCritDamage = newCritDamage + augment.critDamage.value

        elseif augment.critChance.operation == "multiply" then
            newCritDamage = newCritDamage * augment.critDamage.value

        end

        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critDamageMult = newCritDamage})
    end

    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(oldPrimaryAbility, newPrimaryAbility))

    -- count stat
    statList[config.getParameter("itemName")] = (statList[config.getParameter("itemName")] or 0) + 1
    
    
    output:setInstanceValue("statList", statList)

    output:setInstanceValue("isModded", true)

    return output:descriptor(), 1
  
  end
end
