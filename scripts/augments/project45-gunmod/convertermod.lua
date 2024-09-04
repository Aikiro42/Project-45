require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

local plurals = {
  projectile = "projectiles",
  hitscan = "hitscans",
  beam = "beam",
  summoned = "summoned projectiles"
}

function apply(output, augment)

  local conversion = augment
  local input = output:descriptor()

  -- local primaryAbility = sb.jsonMerge(output.config.primaryAbility or {}, input.parameters.primaryAbility or {})
  local primaryAbility = output:instanceValue("primaryAbility", {})
  local newPrimaryAbility = input.parameters.primaryAbility or {}
  local modSlots = input.parameters.modSlots or {}
  local statAugment = {}

  -- CONVERSION PROCESS

  local animationCustom = sb.jsonMerge(output.config.animationCustom or {}, input.parameters.animationCustom or {})
  local newAnimationCustom = input.parameters.animationCustom or {}
  local oldProjectileKind = primaryAbility.projectileKind
  local gunCategory = output.config.project45GunModInfo.category
  newPrimaryAbility.projectileKind = conversion -- conversion must be a valid projectile kind

  -- Conversion balance changes
  --[[
  
  Notes:
  - charge parameters aren't changed because they're independent of the projectile kind.
    - I should know, I programmed it such that different projectile kinds have different interactions
      with charge mechanics.
    - This may change if bugs arise.
  
  - hitscans are kinda better than projectiles in that the damage is usually instant

  - beams are minimally affected by projectileCount and multishot, and unaffected by spread.

  - summons are quite powerful in that they're like hitscans but recoil-dampening skill requirement is removed
  
  --]]

  local conversionConfig = root.assetJson("/configs/project45/project45_conversionmod.config")

  -- conversion to beam
  if conversion == "beam" then

    -- multiply by damageConversionFactor if converting to beam
    statAugment.baseDamage = statAugment.baseDamage or {}
    statAugment.baseDamage.rebaseMult = conversionConfig.damageConversionFactor
    -- newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) * conversionConfig.damageConversionFactor

    -- change sounds reminiscent to that of generic beam
    construct(newAnimationCustom, "sounds")
    local defaultBeamSounds = conversionConfig.defaultBeamSounds
    newAnimationCustom.sounds.fireStart = defaultBeamSounds.fireStart
    newAnimationCustom.sounds.fireLoop = defaultBeamSounds.fireLoop
    newAnimationCustom.sounds.fireEnd = defaultBeamSounds.fireEnd

  -- conversion to anything BUT beam
  else

    -- conversion from projectile to hitscan
    if oldProjectileKind == "projectile" and conversion == "hitscan" then
      -- multiply by damageConversionFactor from projectile to hitscan
      -- newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) * conversionConfig.damageConversionFactor
      statAugment.baseDamage = statAugment.baseDamage or {}
      statAugment.baseDamage.rebaseMult = conversionConfig.damageConversionFactor
    
    -- conversion from hitscan/beam to projectile
    elseif (oldProjectileKind == "hitscan" or oldProjectileKind == "beam") and conversion == "projectile" then
      -- divide by damageConversionFactor from hitscan/beam to projectile
      -- newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) / conversionConfig.damageConversionFactor
      statAugment.baseDamage = statAugment.baseDamage or {}
      statAugment.baseDamage.rebaseMult = 1 / conversionConfig.damageConversionFactor
    end

    -- conversion to summoned
    if conversion == "summoned" then
      statAugment.baseDamage = statAugment.baseDamage or {}
      statAugment.baseDamage.rebaseMult = conversionConfig.damageConversionFactor * conversionConfig.summonedDamageMultiplier
      -- newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) * conversionConfig.damageConversionFactor * conversionConfig.summonedDamageMultiplier
    end

    -- conversion from sommunied
    if oldProjectileKind == "summoned" then
      statAugment.baseDamage = statAugment.baseDamage or {}
      statAugment.baseDamage.rebaseMult = 1 / (conversionConfig.damageConversionFactor * conversionConfig.summonedDamageMultiplier)
      -- newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) / (conversionConfig.damageConversionFactor * conversionConfig.summonedDamageMultiplier)
    end

    -- converting from beam; widen spread as this may be set to a negiligible value
    if oldProjectileKind == "beam" then
      construct(newPrimaryAbility, "beamParameters")
      statAugment.spread = statAugment.spread or {}
      statAugment.spread.rebaseMult = 1 / conversionConfig.projectileSpreadDividend
      -- newPrimaryAbility.spread = (primaryAbility.beamParameters.beamWidth or 5) / conversionConfig.projectileSpreadDividend
    end

    -- SOUND CHANGES
    construct(newAnimationCustom, "sounds")

    if oldProjectileKind == "beam" and conversionConfig.removeFireLoopSounds then
      -- remove fire start/loop/end sounds if converting from beam
      newAnimationCustom.sounds.fireStart = {}
      newAnimationCustom.sounds.fireLoop = {}
      newAnimationCustom.sounds.fireEnd = {}
    end

    -- if gun has no "fire" sound,
    newAnimationCustom.sounds.fire = animationCustom.sounds.fire or {}
    if #newAnimationCustom.sounds.fire == 0 then
      if oldProjectileKind == "beam" or gunCategory == "energy" then
        -- beam projectile guns are usually energy ones... so add energy fire sound
        newAnimationCustom.sounds.fire = conversionConfig.defaultFireSounds.energy
      elseif gunCategory == "ballistic" then
        -- otherwise, just add a generic rifle sound
        newAnimationCustom.sounds.fire = conversionConfig.defaultFireSounds.ballistic
      elseif gunCategory == "experimental" then
        newAnimationCustom.sounds.fire = conversionConfig.defaultFireSounds.experimental
      else
        newAnimationCustom.sounds.fire = conversionConfig.defaultFireSounds.default
      end
    end

  end

  output:setInstanceValue("primaryAbility", newPrimaryAbility)
  output:setInstanceValue("animationCustom", newAnimationCustom)

  return output, statAugment
end
