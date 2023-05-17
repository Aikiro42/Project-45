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
    
    local modSlots = input.parameters.modSlots or {} -- retrieve occupied slots
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

    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(oldPrimaryAbility, newPrimaryAbility))

    -- register ammo   
    modSlots.ammoType = {
      augment.modName,
      config.getParameter("itemName")
    }
    output:setInstanceValue("modSlots", modSlots)

    output:setInstanceValue("isModded", true)

    return output:descriptor(), 1
  
  end
end
