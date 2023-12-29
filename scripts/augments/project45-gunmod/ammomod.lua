require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod/convertermod.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

local convertermod_apply = apply

function apply(input)

  local output = Item.new(input)
  local modInfo = sb.jsonMerge(output.config.project45GunModInfo, input.parameters.project45GunModInfo)
  if not modInfo then return end

  local augment = config.getParameter("augment")
  
  if augment then

    -- MOD INSTALLATION GATES

    local upgradeCost = augment.upgradeCost
    local upgradeCapacity, upgradeCount

    -- do not install if ammo type is already installed
    local modSlots = input.parameters.modSlots or {}
    if modSlots.ammoType then
      return gunmodHelper.addMessage(input, "Ammo mod slot Occupied")
    end

    -- deny installation if upgrade capacity is not enough
    if upgradeCost then
      upgradeCount = input.parameters.upgradeCount or 0
      upgradeCapacity = modInfo.upgradeCapacity or -1
      if upgradeCapacity > -1 and upgradeCount + upgradeCost > upgradeCapacity then
        sb.logError("(ammomod.lua) Ammo mod application failed: Not Enough Upgrade Capacity")
        return gunmodHelper.addMessage(input, "Not Enough Upgrade Capacity")
      end
    end

    -- deny installation if ammo rejects gun
    if augment.incompatibleWeapons then
      local deniedWeapons = set.new(augment.incompatibleWeapons)
      if deniedWeapons[input.name] then
          sb.logError("(ammomod.lua) Mod application failed: Mod incompatible with " .. input.name)
          return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
      end
    end

    -- deny installation if gun rejects ammo
    if modInfo.incompatibleMods then
      local deniedMods = set.new(modInfo.incompatibleMods)
      if deniedMods[config.getParameter("itemName")] then
          sb.logError("(ammomod.lua) Mod application failed: Mod incompatible with " .. input.name)
          return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
      end
    end

    local bypassCompatChecks = false

    -- check if ammo accepts gun
    if augment.compatibleWeapons then
      local acceptedWeapons = set.new(augment.compatibleWeapons)
      bypassCompatChecks = bypassCompatChecks or acceptedWeapons[input.name]
    end

    -- check if gun accepts ammo
    if modInfo.compatibleMods then
      local acceptedMods = set.new(modInfo.compatibleMods)
      bypassCompatChecks = bypassCompatChecks or acceptedMods[config.getParameter("itemName")]
    end

    -- If exclusiveCompatibility and weapon not accepted then
    if augment.exclusiveCompatibility and not bypassCompatChecks then
      sb.logError("(abilitymod.lua) Mod application failed: Mod incompatible with " .. input.name .. " (gun rejects mod)")
      return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
    end      

    if not bypassCompatChecks then 

      -- do not install ammo mod if it does not meet category
      if augment.category ~= "universal"
      and modInfo.category ~= "universal"
      and modInfo.category ~= augment.category
      then
        sb.logError("(ammomod.lua) Ammo mod application failed: category mismatch")
        return gunmodHelper.addMessage(input, "Wrong Category: " .. config.getParameter("shortdescription"))
      end
      
      -- do not install ammo mod if its archetype is not accepted
      local acceptedArchetype = set.new(modInfo.acceptsAmmoArchetype)
      if augment.archetype ~= "universal"
      and not acceptedArchetype["universal"]
      and not acceptedArchetype[augment.archetype]
      then
        sb.logError("(ammomod.lua) Ammo mod application failed: gun does not accept ammo archetype")
        return gunmodHelper.addMessage(input, "Incompatible Mod: " .. config.getParameter("shortdescription"))
      end

    end

    -- MOD INSTALLATION PROCESS

    -- make necessary conversion
    local converted, conversionValid = convertermod_apply(input, true, augment)
    if conversionValid == 0 then
      return gunmodHelper.addMessage(input, "Conversion error: " .. config.getParameter("shortdescription"))
    end
    output = converted -- TESTME: will this work?

    -- prepare to alter stats and the primary ability in general
    local oldPrimaryAbility = output.config.primaryAbility or {}
    local newPrimaryAbility = input.parameters.primaryAbility or {}

    -- alter general projectile settings
    local projectileSettingsList = {
      "multishot",
      "projectileCount",
      "spread"
    }
    for _, v in ipairs(projectileSettingsList) do
      if augment[v] then
        newPrimaryAbility[v] = augment[v] -- or oldPrimaryAbility[v]
      end
    end

    -- alter specific projectile settings
    -- newPrimaryAbility.projectileKind = augment.projectileKind or oldPrimaryAbility.projectileKind -- no need; conversion already done
    local specificSettingsList = {
      "projectileType",
      "summonedProjectileType",
      "projectileParameters",
      "hitscanParameters",
      "beamParameters",
      "summonedProjectileParameters",
      "hideMuzzleFlash",
      "hideMuzzleSmoke"
    }
    for _, v in ipairs(specificSettingsList) do
      newPrimaryAbility[v] = augment[v]
    end

    -- alter muzzle flash color
    if augment.muzzleFlashColor then
      output:setInstanceValue("muzzleFlashColor", augment.muzzleFlashColor)
    end

    -- for audio
    if augment.customSounds then

      construct(input, "parameters", "animationCustom", "sounds")
      for soundName, soundArr in pairs(augment.customSounds) do
        input.parameters.animationCustom.sounds[soundName] = copy(soundArr)
      end

      output:setInstanceValue("animationCustom", input.parameters.animationCustom)
    end

    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(oldPrimaryAbility, newPrimaryAbility))

    -- register ammo
    modSlots.ammoType = {
      augment.modName,
      config.getParameter("itemName"),
      config.getParameter("tooltipFields", {}).objectImage or config.getParameter("inventoryIcon")
    }
    output:setInstanceValue("modSlots", modSlots)
    if upgradeCost then
      output:setInstanceValue("upgradeCount", upgradeCount + upgradeCost)
    end
    output:setInstanceValue("isModded", true)

    return output:descriptor(), 1
  
  end
end
