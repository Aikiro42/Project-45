require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

function apply(input)

  local modInfo = input.parameters.project45GunModInfo
  if not modInfo then return end

  local augment = config.getParameter("augment")
  local output = Item.new(input)
  
  if augment then

    -- MOD INSTALLATION GATES

    -- do not install ammo type if ammo isn't universal and
    -- gun does not affect ammo type
    if augment.type ~= "universal" then
      if not modInfo.acceptsAmmoTypes[augment.type] then return end
    end

    -- do not install ammo type if ammo archetype isn't universal and
    -- gun does not affect ammo archetype

    if not modInfo.acceptsAmmoArchetypes.all and augment.archetype ~= "universal" then
      if augment.archetype == "bullet" then
        local isBullet = modInfo.acceptsAmmoArchetypes.generic or modInfo.acceptsAmmoArchetypes.shotgun
        if not isBullet then return end

      else
        if not modInfo.acceptsAmmoArchetypes[augment.archetype] then return end
      end
    end
    
    
    -- do not install if ammo type is already installed
    local modSlots = input.parameters.modSlots or {}
    if modSlots.ammoType then
        return
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
