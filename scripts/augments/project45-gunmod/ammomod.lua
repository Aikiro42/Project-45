require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

function apply(input)

  local output = Item.new(input)
  local modInfo = sb.jsonMerge(output.config.project45GunModInfo, input.parameters.project45GunModInfo)
  if not modInfo then return end

  local augment = config.getParameter("augment")
  
  if augment then

    -- MOD INSTALLATION GATES

    local upgradeCost = augment.upgradeCost
    local upgradeCapacity, upgradeCount
    if upgradeCost then
      upgradeCount = input.parameters.upgradeCount or 0
      upgradeCapacity = modInfo.upgradeCapacity or -1
      if upgradeCapacity > -1 and upgradeCount + upgradeCost > upgradeCapacity then
        sb.logError("(ammomod.lua) Ammo mod application failed: Not Enough Upgrade Capacity")
        return gunmodHelper.addMessage(input, "Not Enough Upgrade Capacity")
      end
    end

    -- check if mod accepts gun
    if augment.compatibleWeapons then
      local acceptedWeapons = set.new(augment.compatibleWeapons)
      if not acceptedWeapons[input.name] then
          sb.logError("(gunmod.lua) Mod application failed: Mod incompatible with " .. input.name)
          return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
      end
    end

    -- check if mod rejects gun
    if augment.incompatibleWeapons then
      local deniedWeapons = set.new(augment.incompatibleWeapons)
      if deniedWeapons[input.name] then
          sb.logError("(gunmod.lua) Mod application failed: Mod incompatible with " .. input.name)
          return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
      end
    end

      -- check if gun accepts mod
    if modInfo.compatibleMods then
      local acceptedMods = set.new(modInfo.compatibleMods)
      if not acceptedMods[config.getParameter("shortdescription")] then
          sb.logError("(gunmod.lua) Mod application failed: Mod incompatible with " .. input.name)
          return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
      end
    end

    -- check if gun rejects mod
    if modInfo.incompatibleMods then
        local deniedMods = set.new(modInfo.incompatibleMods)
        if not deniedMods[config.getParameter("shortdescription")] then
            sb.logError("(gunmod.lua) Mod application failed: Mod incompatible with " .. input.name)
            return gunmodHelper.addMessage(input, "Incompatible mod: " .. config.getParameter("shortdescription"))    
        end
    end
  
    -- do not install if ammo type is already installed
    local modSlots = input.parameters.modSlots or {}
    if modSlots.ammoType then
      return gunmodHelper.addMessage(input, "Ammo mod slot Occupied")
    end

    local modExceptions = modInfo.modExceptions or {}
    modExceptions.accept = modExceptions.accept or {}
    modExceptions.deny = modExceptions.deny or {}

    -- check if ammo mod is particularly denied
    local denied = set.new(modExceptions.deny)
    if denied[config.getParameter("itemName")] then
      sb.logError("(ammomod.lua) Ammo mod application failed: gun does not accept this specific ammo mod")
      return gunmodHelper.addMessage(input, "Incompatible Mod: " .. config.getParameter("shortdescription"))
    end

    -- check if ammo mod is particularly accepted
    local accepted = set.new(modExceptions.accept)
    if not accepted[config.getParameter("itemName")] then 

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
    newPrimaryAbility.projectileKind = augment.projectileKind or oldPrimaryAbility.projectileKind
    newPrimaryAbility.projectileType = augment.projectileType or oldPrimaryAbility.projectileType
    newPrimaryAbility.summonedProjectileType = augment.summonedProjectileType or oldPrimaryAbility.summonedProjectileType
    newPrimaryAbility.projectileParameters = augment.projectileParameters
    newPrimaryAbility.hitscanParameters = augment.hitscanParameters
    newPrimaryAbility.beamParameters = augment.beamParameters
    newPrimaryAbility.summonedProjectileParameters = augment.summonedProjectileParameters
    
    newPrimaryAbility.hideMuzzleFlash = augment.hideMuzzleFlash
    newPrimaryAbility.hideMuzzleSmoke = augment.hideMuzzleSmoke

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
      config.getParameter("inventoryIcon")
    }
    output:setInstanceValue("modSlots", modSlots)
    if upgradeCost then
      output:setInstanceValue("upgradeCount", upgradeCount + upgradeCost)
    end
    output:setInstanceValue("isModded", true)

    return output:descriptor(), 1
  
  end
end
