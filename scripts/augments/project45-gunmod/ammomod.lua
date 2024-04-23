require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod/convertermod.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

local convertermod_apply = apply

function apply(output, augment)

  local input = output:descriptor()
  local modInfo = output:instanceValue("project45GunModInfo")

  if augment then

    -- assume conversion is done from apply.lua

    -- prepare to alter stats and the primary ability in general
    local oldPrimaryAbility = output.config.primaryAbility or {}
    local newPrimaryAbility = output:instanceValue("primaryAbility", {})

    -- alter general projectile settings
    local projectileSettingsList = {"multishot", "projectileCount", "spread"}
    for _, v in ipairs(projectileSettingsList) do
      if augment[v] then
        newPrimaryAbility[v] = augment[v] -- or oldPrimaryAbility[v]
      end
    end

    -- alter specific projectile settings
    -- newPrimaryAbility.projectileKind = augment.projectileKind or oldPrimaryAbility.projectileKind -- no need; conversion already done
    local specificSettingsList = {"projectileType", "summonedProjectileType", "projectileParameters",
                                  "hitscanParameters", "beamParameters", "summonedProjectileParameters",
                                  "hideMuzzleFlash", "hideMuzzleSmoke"}
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

    return output

  end
end
