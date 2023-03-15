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
    
    -- local modTypeCheck = output:instanceValue("rejectsModtype", {})
    local modSlots = input.parameters.modSlots or {} -- retrieve occupied slots
    local statList = input.parameters.statList or {} -- retrieve stat mods
    
    -- retrieve dictionary of rejected types
    local rejectsModType = output:instanceValue("rejectsModType", {})
    local acceptsModSlot = output:instanceValue("acceptsModSlot", {
      --[[
      - rail
      - sights
      - muzzle
      - underbarrel
      - barrel
      - receiver
      - stock
      - ammotype
      - material
      --]]
      rail = true,
      sights = true,
      muzzle = true,
      underbarrel = true,
      barrel = true,
      receiver = true,
      stock = true,
      ammotype = true,
      material = true,
    })
    
    -- retrieve stat limit
    local statModLimit = input.parameters.primaryAbility and
      input.parameters.primaryAbility.statModLimit or 0

    -- MOD INSTALLATION GATES
    
    -- do not install mod if slot is occupied
    -- this ensures that mod installations are a one-time thing
    -- implies that you can't install a different alt ability if
    -- you installed the wrong one (you need to use the disassembler)
    if modSlots[augment.slots] then return end

    -- do not install mod if stat mod limit is reached
    if statModLimit > 0 and #statList > statModLimit then return end

    -- do not install mod if gun denies installation of such type/slot
    if rejectsModType[augment.type] then return end
    if augment.type ~= "stat" and not acceptsModSlot[augment.slot] then return end

    -- MOD INSTALLATION PROCESS

    -- alter or set ability type if present
    if augment.altAbilityType and input.parameters.altAbilityType ~= augment.altAbilityType then
    
      output:setInstanceValue("altAbilityType", augment.altAbilityType)
      output:setInstanceValue("twoHanded", true)  -- make weapon two-handed to allow usage of alt ability
      
      -- merge ability parameters
      if augment.altAbility then
        output:setInstanceValue("altAbility", sb.jsonMerge(input.parameters.altAbility or {}, augment.altAbility))
      end

    end

    -- for muzzle mods
    if augment.muzzleOffsetAdd then
      local oldMuzzleOffset = output:instanceValue("muzzleOffset")
      output:setInstanceValue("muzzleOffset", vec2.add(oldMuzzleOffset, augment.muzzleOffsetAdd))
    end

    -- prepare to alter stats and the primary ability in general
    local oldPrimaryAbility = output:instanceValue("primaryAbility")
    local newPrimaryAbility = {}

    -- replace general primaryability stats
    if augment.primaryAbility then
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, augment.primaryAbility)
    end

    -- multiply base damage directly
    if augment.baseDamageMult then
      local newBaseDamage = math.min(oldPrimaryAbility.baseDamage * augment.baseDamageMult, 99)
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {baseDamage = newBaseDamage})
    end

    -- multiply general fire rate directly
    if augment.cycleTimeMult then
      
      -- sb.logInfo(sb.printJson(oldPrimaryAbility))

      local oldCycleTime = oldPrimaryAbility.cycleTime
      
      if type(oldCycleTime) == "table" then
        oldCycleTime = {oldCycleTime[1] * augment.cycleTimeMult, oldCycleTime[2] * augment.cycleTimeMult}
      else
        oldCycleTime = oldCycleTime * augment.cycleTimeMult
      end
      
      local newChargeTime = oldPrimaryAbility.chargeTime * augment.cycleTimeMult
      local newOverchargeTime = oldPrimaryAbility.overchargeTime * augment.cycleTimeMult
      local newFireTime = math.min(oldPrimaryAbility.fireTime * augment.cycleTimeMult, 0.01)

      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
        cycleTime = oldCycleTime,
        chargeTime = newChargeTime,
        overchargeTime = newOverchargeTime,
        fireTime = newFireTime
      })

    end

    -- multiply reloadCostMult
    if augment.reloadCostMult then
      local newReloadCost = math.max(oldPrimaryAbility.reloadCost * augment.reloadCostMult, 0.05)
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {reloadCost = newReloadCost})
    end
    
    if augment.critChanceAdd then
      local newCritChance = math.min(oldPrimaryAbility.critChance + augment.critChanceAdd, 1)
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critChance = newCritChance})
    end

    if augment.critDamageMult then
      local newCritDamage = math.min(oldPrimaryAbility.critDamageMult * augment.critDamageMult, 10)
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {critDamageMult = newCritDamage})
    end

    if augment.maxAmmoMult then
      local newMaxAmmo = oldPrimaryAbility.maxAmmo * augment.maxAmmoMult
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
        maxAmmo = newMaxAmmo,
      })
      if oldPrimaryAbility.bulletsPerReload >= oldPrimaryAbility.maxAmmo then
        local newBulletsPerReload = oldPrimaryAbility.bulletsPerReload * augment.maxAmmoMult
        newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
          bulletsPerReload = newBulletsPerReload,
        })
      end
    end

    if augment.mobilityMult then

      local newMovementSpeedFactor = oldPrimaryAbility.movementSpeedFactor * augment.mobilityMult
      local newJumpHeightFactor = oldPrimaryAbility.jumpHeightFactor * augment.mobilityMult

      if oldPrimaryAbility.movementSpeedFactor < 1 then
        newMovementSpeedFactor = math.min(1, newMovementSpeedFactor)
      end

      if oldPrimaryAbility.jumpHeightFactor < 1 then
        newJumpHeightFactor = math.min(1, newJumpHeightFactor)
      end

      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
        movementSpeedFactor = newMovementSpeedFactor,
        jumpHeightFactor = newJumpHeightFactor
      })
    end

    if augment.recoilMult then
      local newRecoilMult = math.max(oldPrimaryAbility.recoilMult * augment.recoilMult, 0.01)
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {recoilMult = newRecoilMult})
    end

    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(oldPrimaryAbility, newPrimaryAbility))

    -- for visible weapon parts like grips, etc.
    if augment.animationCustom then
      output:setInstanceValue("animationCustom", sb.jsonMerge(input.parameters.animationCustom or {}, augment.animationCustom))
    end

    -- add mod name to list of installed mods or stats
    if augment.type ~= "stat" then
      modSlots[augment.slot] = {
        augment.modName,
        config.getParameter("itemName")
      }
    else
      statList[#statList+1] = config.getParameter("itemName")
    end
    
    output:setInstanceValue("modSlots", modSlots)
    sb.logInfo(sb.printJson(statList))
    output:setInstanceValue("statList", statList)
    output:setInstanceValue("isModded", true)
    -- print(sb.printJson(output:descriptor()))

    sb.logInfo(sb.printJson(output:descriptor()))

    return output:descriptor(), 1

  
  end
end
