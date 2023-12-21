require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

local plurals = {
  projectile = "projectiles",
  hitscan = "hitscans",
  beam = "beam",
  summoned = "summons"
}

function apply(input)

  local conversion = config.getParameter("conversion")
  local output = Item.new(input)
  local modInfo = sb.jsonMerge(output.config.project45GunModInfo, input.parameters.project45GunModInfo)

  local primaryAbility = sb.jsonMerge(output.config.primaryAbility or {}, input.parameters.primaryAbility or {})
  local newPrimaryAbility = input.parameters.primaryAbility or {}
  local modSlots = input.parameters.modSlots or {}

  -- CONVERSION GATES

  local upgradeCost = config.getParameter("upgradeCost")
  local upgradeCapacity, upgradeCount
  if upgradeCost then
    upgradeCount = input.parameters.upgradeCount or 0
    upgradeCapacity = modInfo.upgradeCapacity or -1
    if upgradeCapacity > -1 and upgradeCount + upgradeCost > upgradeCapacity then
      sb.logError("(convertermod.lua) Converter mod application failed: Not Enough Upgrade Capacity")
      return gunmodHelper.addMessage(input, "Not Enough Upgrade Capacity")
    end
  end

  -- Do not proceed if mod slot is occupied
  if modSlots.ammoType then
    sb.logError("(convertermod.lua) Conversion not applied; ammo/conversion mod is installed.")
    return gunmodHelper.addMessage(input, "Ammo mod slot occupied")
  end
  -- Do not proceed if conversion is to same type
  if primaryAbility.projectileKind == conversion then
    sb.logError("(convertermod.lua) Conversion not applied; gun already fires " .. conversion)
    return gunmodHelper.addMessage(input, "Gun already fires " .. plurals[conversion])
  end  

  -- Do not proceed if gun doesn't allow conversion
  construct(output, "config", "project45GunModInfo")
  local whitelist = set.new(output.config.project45GunModInfo.allowsConversion or {})
  if not whitelist[conversion] then
    sb.logError("(convertermod.lua) Conversion not applied; gun does not allow " .. conversion .. " conversion.")
    return gunmodHelper.addMessage(input, "Incompatible converter mod: " .. config.getParameter("shortdescription"))
  end

  -- Do not proceed if conversion is invalid
  if not set.new({"projectile", "hitscan", "beam", "summoned"})[conversion] then
    sb.logError("(convertermod.lua) Invalid projectileKind: " .. conversion)
    return
  end

  -- CONVERSION PROCESS


  local animationCustom = sb.jsonMerge(output.config.animationCustom or {}, input.parameters.animationCustom or {})
  local newAnimationCustom = input.parameters.animationCustom or {}
  local oldProjectileKind = primaryAbility.projectileKind
  local gunCategory = output.config.project45GunModInfo.category
  newPrimaryAbility.projectileKind = conversion  -- conversion must be a valid projectile kind

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

  if conversion == "beam" then
    
    -- multiply by damageConversionFactor if converting to beam
    newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) * conversionConfig.damageConversionFactor
    
    -- change sounds reminiscent to that of generic beam
    construct(newAnimationCustom, "sounds")
    local defaultBeamSounds = conversionConfig.defaultBeamSounds
    newAnimationCustom.sounds.fireStart = defaultBeamSounds.fireStart
    newAnimationCustom.sounds.fireLoop = defaultBeamSounds.fireLoop
    newAnimationCustom.sounds.fireEnd = defaultBeamSounds.fireEnd

  else

    -- projectile-hitscan relationship
    if oldProjectileKind == "projectile"
    and conversion == "hitscan" then
      -- multiply by damageConversionFactor from projectile to hitscan
      newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) * conversionConfig.damageConversionFactor
    elseif (oldProjectileKind == "hitscan" or oldProjectileKind == "beam")
    and conversion == "projectile" then
      -- divide by damageConversionFactor from hitscan/beam to projectile
      newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) / conversionConfig.damageConversionFactor
    end

    if conversion == "summoned" then
      newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) * conversionConfig.damageConversionFactor * conversionConfig.summonedDamageMultiplier
    end

    if oldProjectileKind == "summoned" then
      newPrimaryAbility.baseDamage = (primaryAbility.baseDamage or 5) / (conversionConfig.damageConversionFactor * conversionConfig.summonedDamageMultiplier)
    end
    
    -- widen spread if converting from beam
    if oldProjectileKind == "beam" then
      construct(newPrimaryAbility, "beamParameters")
      newPrimaryAbility.spread = (primaryAbility.beamParameters.beamWidth or 5) / conversionConfig.projectileSpreadDividend
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
  
  modSlots.ammoType = {
    config.getParameter("shortdescription"),
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