require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

function apply(input)

  local modInfo = input.parameters.project45GunModInfo
  if not modInfo then return end

  local augment = config.getParameter("augment")
  local output = Item.new(input)
  
  if augment then

    -- MOD INSTALLATION GATES

    -- do not install if ammo type is already installed
    local modSlots = input.parameters.modSlots or {}
    if modSlots.ammoType then
        return
    end

    local modExceptions = modInfo.modExceptions or {}
    modExceptions.accept = modExceptions.accept or {}
    modExceptions.deny = modExceptions.deny or {}

    -- check if ammo mod is particularly denied
    local denied = set.new(modExceptions.deny)
    if denied[config.getParameter("itemName")] then
      sb.logError("(ammomod.lua) Ammo mod application failed: gun does not accept this specific ammo mod")
      return
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
        return
      end
      
      -- do not install ammo mod if its archetype is not accepted
      local acceptedArchetype = set.new(modInfo.acceptsAmmoArchetype)
      if augment.archetype ~= "universal"
      and not acceptedArchetype["universal"]
      and not acceptedArchetype[augment.archetype]
      then
        sb.logError("(ammomod.lua) Ammo mod application failed: gun does not accept ammo archetype")
        return
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
      newPrimaryAbility[v] = augment[v] -- or oldPrimaryAbility[v]
    end

    -- alter specific projectile settings
    newPrimaryAbility.projectileKind = augment.projectileKind or oldPrimaryAbility.projectileKind
    newPrimaryAbility.projectileType = augment.projectileType or oldPrimaryAbility.projectileType
    newPrimaryAbility.projectileParameters = augment.projectileParameters
    newPrimaryAbility.hitscanParameters = augment.hitscanParameters
    newPrimaryAbility.beamParameters = augment.beamParameters
    newPrimaryAbility.summonParameters = augment.summonParameters
    
    newPrimaryAbility.hideMuzzleFlash = augment.hideMuzzleFlash
    newPrimaryAbility.hideMuzzleSmoke = augment.hideMuzzleSmoke

    -- alter muzzle flash color
    if augment.muzzleFlashColor then
      output:setInstanceValue("muzzleFlashColor", augment.muzzleFlashColor)
    end

    -- for audio
    if augment.customSounds then
      output:setInstanceValue("animationCustom", sb.jsonMerge(input.parameters.animationCustom or {}, {
        sounds = augment.customSounds
      }))
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
    -- sb.logInfo(sb.printJson(modSlots))
    output:setInstanceValue("isModded", true)

    return output:descriptor(), 1
  
  end
end
