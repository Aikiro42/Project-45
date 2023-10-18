require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

function apply(input)

  local conversion = config.getParameter("conversion")
  local output = Item.new(input)

  local primaryAbility = sb.jsonMerge(output.config.primaryAbility or {}, input.parameters.primaryAbility or {})
  local modSlots = input.parameters.modSlots or {}

  -- CONVERSION GATES

  -- Do not proceed if mod slot is occupied
  if modSlots.ammoType then
    sb.logError("(convertermod.lua) Conversion not applied; ammo/conversion mod is installed.")
    return
  end

  -- Do not proceed if gun doesn't allow conversion
  construct(output, "config", "project45GunModInfo")
  local whitelist = set.new(output.config.project45GunModInfo.allowsConversion or {})
  if not whitelist[conversion] then
    sb.logError("(convertermod.lua) Conversion not applied; gun does not allow " .. conversion .. " conversion.")
    return
  end

  -- Do not proceed if conversion is to same type
  if primaryAbility.projectileKind == conversion then
    sb.logError("(convertermod.lua) Conversion not applied; gun already fires " .. conversion)
    return
  end

  -- Do not proceed if conversion is invalid
  if not set.new({"projectile", "hitscan", "beam", "summoned"})[conversion] then
    sb.logError("(convertermod.lua) Invalid projectileKind: " .. conversion)
    return
  end

  -- CONVERSION PROCESS


  local animationCustom = sb.jsonMerge(output.config.animationCustom or {}, input.parameters.animationCustom or {})
  local oldProjectileKind = primaryAbility.projectileKind
  local gunCategory = output.config.project45GunModInfo.category
  primaryAbility.projectileKind = conversion  -- conversion must be a valid projectile kind

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
    primaryAbility.baseDamage = (primaryAbility.baseDamage or 5) * conversionConfig.damageConversionFactor
    
    -- change sounds reminiscent to that of generic beam
    construct(animationCustom, "sounds")
    local defaultBeamSounds = conversionConfig.defaultBeamSounds
    animationCustom.sounds.fireStart = defaultBeamSounds.fireStart
    animationCustom.sounds.fireLoop = defaultBeamSounds.fireLoop
    animationCustom.sounds.fireEnd = defaultBeamSounds.fireEnd

  else

    -- projectile-hitscan relationship
    if oldProjectileKind == "projectile"
    and conversion == "hitscan" then
      -- multiply by damageConversionFactor from projectile to hitscan
      primaryAbility.baseDamage = (primaryAbility.baseDamage or 5) * conversionConfig.damageConversionFactor
    elseif (oldProjectileKind == "hitscan" or oldProjectileKind == "beam")
    and conversion == "projectile" then
      -- divide by damageConversionFactor from hitscan/beam to projectile
      primaryAbility.baseDamage = (primaryAbility.baseDamage or 5) / conversionConfig.damageConversionFactor
    end

    -- reduce projectileCount and multishot when converting to hitscan to hitscan projectile limit
    if conversion == "hitscan" then
      primaryAbility.projectileCount = math.min(conversionConfig.hitscanProjectileLimit, primaryAbility.projectileCount or 1)
      primaryAbility.multishot = math.min(conversionConfig.hitscanProjectileLimit, primaryAbility.multishot or 1)
      
      -- if product of multishot and projectile count is beyond limit,
      -- normalize such that max possible number of projectiles spawned is limit
      -- i.e. projectileCount * multishot <= limit
      if primaryAbility.projectileCount * primaryAbility.multishot > conversionConfig.hitscanProjectileLimit then
        local factor = math.sqrt(conversionConfig.hitscanProjectileLimit)/conversionConfig.hitscanProjectileLimit
        primaryAbility.projectileCount = math.ceil(primaryAbility.projectileCount * factor)
        primaryAbility.multishot = primaryAbility.multishot * factor
      end
    end

    if conversion == "summoned" then
      primaryAbility.baseDamage = (primaryAbility.baseDamage or 5) * conversionConfig.damageConversionFactor * conversionConfig.summonedDamageMultiplier
    end

    if oldProjectileKind == "summoned" then
      primaryAbility.baseDamage = (primaryAbility.baseDamage or 5) / (conversionConfig.damageConversionFactor * conversionConfig.summonedDamageMultiplier)
    end
    
    -- widen spread if converting from beam
    if oldProjectileKind == "beam" then
      construct(primaryAbility, "beamParameters")
      primaryAbility.spread = (primaryAbility.beamParameters.beamWidth or 5) / conversionConfig.projectileSpreadDividend
    end

    -- SOUND CHANGES
    construct(animationCustom, "sounds")

    if oldProjectileKind == "beam" and conversionConfig.removeFireLoopSounds then
      -- remove fire start/loop/end sounds if converting from beam
      animationCustom.sounds.fireStart = {}
      animationCustom.sounds.fireLoop = {}
      animationCustom.sounds.fireEnd = {}
    end

    -- if gun has no "fire" sound,
    animationCustom.sounds.fire = animationCustom.sounds.fire or {}
    if #animationCustom.sounds.fire == 0 then
      if oldProjectileKind == "beam" or gunCategory == "energy" then
        -- beam projectile guns are usually energy ones... so add energy fire sound
        animationCustom.sounds.fire = conversionConfig.defaultFireSounds.energy
      elseif gunCategory == "ballistic" then
        -- otherwise, just add a generic rifle sound
        animationCustom.sounds.fire = conversionConfig.defaultFireSounds.ballistic
      elseif gunCategory == "experimental" then
        animationCustom.sounds.fire = conversionConfig.defaultFireSounds.experimental
      else
        animationCustom.sounds.fire = conversionConfig.defaultFireSounds.default
      end
    end
    
  end

  output:setInstanceValue("primaryAbility", primaryAbility)
  output:setInstanceValue("animationCustom", animationCustom)
  
  modSlots.ammoType = {
    config.getParameter("shortdescription"),
    config.getParameter("itemName"),
    config.getParameter("inventoryIcon")
  }

  output:setInstanceValue("modSlots", modSlots)
  output:setInstanceValue("isModded", true)

  return output:descriptor(), 1
end