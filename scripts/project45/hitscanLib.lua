require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/scripts/set.lua"

hitscanLib = {}

local modConfig = root.assetJson("/configs/project45/project45_generalconfig.config")

function hitscanLib:fireChainBeam()
  if world.lineTileCollision(mcontroller.position(), self:firePosition()) then return end

  self:startFireLoop()
  if storage.ammo > 0 then
    self:recoil(false, 0.1)
    self:screenShake(self.currentScreenShake * 4)
  end

  animator.setAnimationState("gun", "firingLoop")

  local beamDamageConfig = sb.jsonMerge(self.beamParameters.beamDamageConfig)

  local recoilTimer = 0
  local beamTimeout = self.currentCycleTime
  local ammoConsumeTimer = beamTimeout
  local consumedAmmo = false

  local originalStatusEffects = sb.jsonMerge(beamDamageConfig.statusEffects)

  local debug_punchthrough = 3
  local chainScanResults, chain, hitEntityIds, chainWorldLines, chainDamageAreas
  
  -- loop to maintain beam fire
  while ((self.chargeTime + self.overchargeTime <= 0 or not self.semi)
  and self:triggering()
  or (
    not self:triggering()
    and self.chargeTimer > 0
    and self.semi
  ))
  and (not self.beamParameters.consumeAmmoOverTime or storage.ammo > 0)
  and not world.lineTileCollision(mcontroller.position(), self:firePosition())
  do

    self.isFiring = true
    -- TODO: make parameters dymamic
    chainScanResults = self:chainScan(100, false, debug_punchthrough, false)
    chain = chainScanResults[1]
    hitEntityIds = chainScanResults[2]
    chainWorldLines = {}
    chainDamageAreas = {}
    for i=2, #chain do
      table.insert(chainWorldLines, {chain[i-1], chain[i]})
      table.insert(chainDamageAreas, 
        {
          vec2.sub(chain[i-1], mcontroller.position()),
          vec2.sub(chain[i], mcontroller.position())
        }
      )
    end  

    if ammoConsumeTimer >= beamTimeout then

      if self:jam() then break end
      
      ammoConsumeTimer = 0
      if self.beamParameters.consumeAmmoOverTime or not consumedAmmo then
        self:updateAmmo(-self.ammoPerShot)
        storage.unejectedCasings = storage.unejectedCasings + math.min(storage.ammo, self.ammoPerShot)
        consumedAmmo = true
      end

      -- update charge damage multiplier
      if self.overchargeTime > 0 then
        self.chargeDamageMult = 1 + (self.chargeTimer - self.chargeTime)/self.overchargeTime
      end

      -- update base damage accordingly
      local multishot = self.projectileCount * self:rollMultishot()
      beamDamageConfig.baseDamage = self:damagePerShot(true) * multishot
    
      if self.critFlag then
        if self.enableMuzzleCritParticles then
          animator.burstParticleEmitter("muzzleCrit")
        end
        beamDamageConfig.statusEffects = sb.jsonMerge(beamDamageConfig.statusEffects, { "project45critdamaged" })
        self.critFlag = false
      else
        beamDamageConfig.statusEffects = sb.jsonMerge(originalStatusEffects)
      end
      -- generate damage source lines
      -- coordinates are based off mcontroller position
      self.weapon.ownerDamageWasSet = true
      self.weapon.ownerDamageCleared = false
      local finalDamageSources = {}
      for _, chainDamageArea in ipairs(chainDamageAreas) do
        table.insert(finalDamageSources, self.weapon:damageSource(beamDamageConfig, chainDamageArea))
      end
      activeItem.setDamageSources(finalDamageSources)

    else
      self.weapon:setDamage()
    end

    -- VFX

    self:muzzleFlash(true)
    
    recoilTimer = recoilTimer + self.dt
    if recoilTimer >= 0.1 then
      self:screenShake(self.currentScreenShake, 0.01)
      recoilTimer = 0
    end
    self:recoil(false, self.recoilMult * 0.1)

    --vfx

    local life = self.hitscanParameters.hitscanFadeTime or 0.5
    for _, chainLine in ipairs(chainWorldLines) do
      local fuzz = (0.5 + 0.5 * math.random())
      local innerFuzz = (0.5 + 0.5 * math.random())
      table.insert(self.projectileStack, {
        width = self.beamParameters.beamWidth * fuzz,
        origin = chainLine[1],
        destination = chainLine[2],
        lifetime = life,
        maxLifetime = life,
        color = self.beamParameters.beamColor
      })

      if self.beamParameters.beamInnerWidth > 0 then
        table.insert(self.projectileStack, {
          width = self.beamParameters.beamInnerWidth * innerFuzz,
          origin = chainLine[1],
          destination = chainLine[2],
          lifetime = life,
          maxLifetime = life,
          color = {255,255,255}
        })
      end   
    end

    -- hitscan vfx
    local hitscanActionsOnReap = {
      {
        action="loop",
        count=6,
        body={
          {
            action="particle",
            specification={
              type="ember",
              size=1,
              color=self.beamParameters.beamColor or {255, 255, 200, 255},
              light=self.beamParameters.beamColor or {65, 65, 51},
              fullbright=true,
              destructionTime=0.2,
              destructionAction="shrink",
              fade=0.9,
              initialVelocity={0, 5},
              finalVelocity={0, -50},
              approach={0, 30},
              timeToLive=0,
              layer="middle",
              variance={
                position={0.25, 0.25},
                size=0.5,
                initialVelocity={10, 10},
                timeToLive=0.2
              }
            }
          }
        }
      }
    }

    for k=2, #chain do
      world.spawnProjectile(
        "invisibleprojectile",
        chain[k],
        activeItem.ownerEntityId(),
        {0, 1},
        false,
        {
          damageType = "NoDamage",
          power = 0,
          timeToLive = 0,
          actionOnReap = hitscanActionsOnReap
        }
      )
    end

    ammoConsumeTimer = ammoConsumeTimer + self.dt

    coroutine.yield()
  end

  self:stopFireLoop()

  self.isFiring = false
  self.muzzleProjectileFired = false

  hitreg = self:hitscan(true)
  beamEnd = hitreg[2]
  animator.setAnimationState("gun", "firing")

  activeItem.setScriptedAnimationParameter("beamLine", nil)
  
  if not self.alwaysMaintainCharge and self.resetChargeOnFire then self.chargeTimer = 0 end
  
  if self.beamParameters.ejectCasingsOnBeamEnd then
    self:setState(self.ejecting)
  else
    if storage.ammo <= 0 then
      self.triggered = true
      animator.setAnimationState("chamber", "filled")
    end
  end
  
end

function hitscanLib:fireChain()
  -- TODO: make chainScan arguments dynamic
  local debug_punchthrough = 3
  local chainScanResults = self:chainScan(100, false, debug_punchthrough, false)
  local chain = chainScanResults[1]
  local hitEntityIds = chainScanResults[2]
  -- chain projectiles only fire one chain
  local nProjs = self.projectileCount * self:rollMultishot()
  local finalDamage = self:damagePerShot(true) * nProjs

  local chainScanInfos = {}
  
  -- get damage source (line) information
  for i=2, #chain do

      local damageArea = {
        vec2.sub(chain[i-1], mcontroller.position()),
        vec2.sub(chain[i], mcontroller.position())
      }

      local hitEntityId = hitEntityIds[i-1]
      
      local damageConfig = {
        -- multiply nProjsOverflowMult to final damage to compensate for lost multishot
        baseDamage = finalDamage,
        timeout = self.currentCycleTime,
      }
      damageConfig = sb.jsonMerge(damageConfig, self.hitscanParameters.hitscanDamageConfig or {})
      if self.critFlag then 
        if self.enableMuzzleCritParticles then
          animator.burstParticleEmitter("muzzleCrit")
        end
        damageConfig.statusEffects = sb.jsonMerge(damageConfig.statusEffects, {"project45critdamaged"})
        self.critFlag = false
      end
      damageConfig.timeoutGroup = "project45projectile" .. i

      table.insert(chainScanInfos, {
          damageConfig,
          damageArea,
          {chain[i-1], chain[i], hitEntityId},
          finalDamage
        }
      )

    end
    --]]

    -- generate damage source lines
    -- coordinates are based off mcontroller position
    self.weapon.ownerDamageWasSet = true
    self.weapon.ownerDamageCleared = false
    local finalDamageSources = {}
    for _, chainScanInfo in ipairs(chainScanInfos) do
      table.insert(finalDamageSources, self.weapon:damageSource(chainScanInfo[1], chainScanInfo[2]))
    end
    activeItem.setDamageSources(finalDamageSources)
  
    --vfx

    local life = self.hitscanParameters.hitscanFadeTime or 0.5
    for _, chainScanInfo in ipairs(chainScanInfos) do
      
      table.insert(self.projectileStack, {
        width = self.hitscanParameters.hitscanWidth,
        origin = chainScanInfo[3][1],
        destination = chainScanInfo[3][2],
        lifetime = life,
        maxLifetime = life,
        color = self.hitscanParameters.hitscanColor
      })

      if self.hitscanParameters.hitscanBrightness > 0 then
        table.insert(self.projectileStack, {
          width = self.hitscanParameters.hitscanWidth * self.hitscanParameters.hitscanBrightness,
          origin = chainScanInfo[3][1],
          destination = chainScanInfo[3][2],
          lifetime = life,
          maxLifetime = life,
          color = {255,255,255}
        })
      end   
    end

    -- hitscan vfx
    local hitscanActionsOnReap = {
      {
        action="loop",
        count=6,
        body={
          {
            action="particle",
            specification={
              type="ember",
              size=1,
              color=self.hitscanParameters.hitscanColor or {255, 255, 200, 255},
              light={65, 65, 51},
              fullbright=true,
              destructionTime=0.2,
              destructionAction="shrink",
              fade=0.9,
              initialVelocity={0, 5},
              finalVelocity={0, -50},
              approach={0, 30},
              timeToLive=0,
              layer="middle",
              variance={
                position={0.25, 0.25},
                size=0.5,
                initialVelocity={10, 10},
                timeToLive=0.2
              }
            }
          }
        }
      }
    }

    -- actionsOnHit
    for i, a in ipairs(self.hitscanParameters.hitscanActionOnHit) do
      table.insert(hitscanActionsOnReap, a)
    end
    
    for _, chainScanInfo in ipairs(chainScanInfos) do
      world.spawnProjectile(
        "invisibleprojectile",
        chainScanInfo[3][2],
        activeItem.ownerEntityId(),
        self:aimVector(3.14),
        false,
        {
          damageType = "NoDamage",
          power = chainScanInfo[4],
          timeToLive = 0,
          actionOnReap = hitscanActionsOnReap
        }
      )
    end

end

function hitscanLib:chainScan(scanLength, ignoresTerrain, punchThrough, scanUntilCursor)
    local firstHit = self:hitscan(true, 0, scanLength, ignoresTerrain, 0, scanUntilCursor, 0, self:firePosition(), true)
    local chainScanLengthLimit = scanLength / 2
    local chain = {firstHit[1], firstHit[2]}
    local firstHitEntityIds = firstHit[3]
    
    if #firstHitEntityIds <= 0 then
      return {chain, {}}
    end
    
    local chainEntityIds = {firstHitEntityIds[1]}
    local alreadyHit = set.new(chainEntityIds)

    for i=1, punchThrough do

      local nextEntityIdCandidates = world.entityQuery(chain[#chain], scanLength, {
        withoutEntityId = entity.id(),
        includedTypes = {"monster", "npc", "player"},
        order = "nearest"
      })

      if #nextEntityIdCandidates < 2 then break end

      local nextEntityId = nil
      for j=1, #nextEntityIdCandidates do
        if not alreadyHit[nextEntityIdCandidates[j]] then
          nextEntityId = nextEntityIdCandidates[j]
          break
        end
      end
      
      if not nextEntityId then break end
      
      local nextPosition = world.entityPosition(nextEntityId)

      chainScanLengthLimit = chainScanLengthLimit - world.magnitude(chain[#chain], nextPosition)
      sb.logInfo(chainScanLengthLimit)
      if chainScanLengthLimit <= 0 then break end

      table.insert(chainEntityIds, nextEntityId)
      alreadyHit[nextEntityId] = true
      table.insert(chain, nextPosition)
      
    end

    if #chain - 1 ~= #chainEntityIds then
      sb.logError("ERROR: CHAIN DOES NOT CORRESPOND TO HIT ENTITIES")
      makeJesusTakeWheel()
    end

    return {chain, chainEntityIds}

end

-- replaces fireProjectile
function hitscanLib:fireHitscan(projectileType)

    -- scan hit down range
    -- hitreg[1] is where the bullet trail emanates,
    -- hitreg[2] is where the bullet trail terminates

    local hitscanInfos = {}
    local finalDamage = self:damagePerShot(true)
    local nProjs = self.projectileCount * self:rollMultishot()
    local nProjsOverflowMult = math.max(1, nProjs/(self.maxProjectileCount or modConfig.hitscanProjectileLimit))
    -- get damage source (line) information
    for i=1, math.min(modConfig.hitscanProjectileLimit, nProjs) do

      local hitReg = self:hitscan(false)
      local damageArea = {
        vec2.sub(hitReg[1], mcontroller.position()),
        vec2.sub(hitReg[2], mcontroller.position())
      }
      
      local damageConfig = {
        -- multiply nProjsOverflowMult to final damage to compensate for lost multishot
        baseDamage = finalDamage*nProjsOverflowMult,
        timeout = self.currentCycleTime,
      }
      damageConfig = sb.jsonMerge(damageConfig, self.hitscanParameters.hitscanDamageConfig or {})
      if self.critFlag then 
        if self.enableMuzzleCritParticles then
          animator.burstParticleEmitter("muzzleCrit")
        end
        damageConfig.statusEffects = sb.jsonMerge(damageConfig.statusEffects, {"project45critdamaged"})
        self.critFlag = false
      end
      damageConfig.timeoutGroup = "project45projectile" .. i

      table.insert(hitscanInfos, {
          damageConfig,
          damageArea,
          hitReg,
          finalDamage
        }
      )

    end
    --]]

    -- generate damage source lines
    -- coordinates are based off mcontroller position
    self.weapon.ownerDamageWasSet = true
    self.weapon.ownerDamageCleared = false
    local finalDamageSources = {}
    for _, hitscanInfo in ipairs(hitscanInfos) do
      table.insert(finalDamageSources, self.weapon:damageSource(hitscanInfo[1], hitscanInfo[2]))
    end
    activeItem.setDamageSources(finalDamageSources)
  
    -- bullet trail info inserted to projectile stack that's being passed to the animation script
    -- each bullet trail in the stack is rendered, and the lifetime is updated in this very script too
    local life = self.hitscanParameters.hitscanFadeTime or 0.5
    for _, hitscanInfo in ipairs(hitscanInfos) do
      
      table.insert(self.projectileStack, {
        width = self.hitscanParameters.hitscanWidth,
        origin = hitscanInfo[3][1],
        destination = hitscanInfo[3][2],
        lifetime = life,
        maxLifetime = life,
        color = self.hitscanParameters.hitscanColor
      })

      if self.hitscanParameters.hitscanBrightness > 0 then
        table.insert(self.projectileStack, {
          width = self.hitscanParameters.hitscanWidth * self.hitscanParameters.hitscanBrightness,
          origin = hitscanInfo[3][1],
          destination = hitscanInfo[3][2],
          lifetime = life,
          maxLifetime = life,
          color = {255,255,255}
        })
      end   
    end

    -- hitscan vfx
    local hitscanActionsOnReap = {
      {
        action="loop",
        count=6,
        body={
          {
            action="particle",
            specification={
              type="ember",
              size=1,
              color=self.hitscanParameters.hitscanColor or {255, 255, 200, 255},
              light={65, 65, 51},
              fullbright=true,
              destructionTime=0.2,
              destructionAction="shrink",
              fade=0.9,
              initialVelocity={0, 5},
              finalVelocity={0, -50},
              approach={0, 30},
              timeToLive=0,
              layer="middle",
              variance={
                position={0.25, 0.25},
                size=0.5,
                initialVelocity={10, 10},
                timeToLive=0.2
              }
            }
          }
        }
      }
    }

    for i, a in ipairs(self.hitscanParameters.hitscanActionOnHit) do
      table.insert(hitscanActionsOnReap, a)
    end
    
    for _, hitscanInfo in ipairs(hitscanInfos) do
      world.spawnProjectile(
        "invisibleprojectile",
        hitscanInfo[3][2],
        activeItem.ownerEntityId(),
        self:aimVector(3.14),
        false,
        {
          damageType = "NoDamage",
          power = hitscanInfo[4],
          timeToLive = 0,
          actionOnReap = hitscanActionsOnReap
        }
      )
    end

end

function hitscanLib:updateProjectileStack()

  -- update projectile stack
  for i, projectile in ipairs(self.projectileStack) do
    self.projectileStack[i].lifetime = self.projectileStack[i].lifetime - self.dt

    -- LERPing; the commented lines work, but they kinda don't look good.
    -- Still leaving it here just in case I feel like reincluding it.
    self.projectileStack[i].origin = vec2.lerp(
      (1 - self.projectileStack[i].lifetime/self.projectileStack[i].maxLifetime)*0.01,
      self.projectileStack[i].origin,
      self.projectileStack[i].destination)
    -- self.projectileStack[i].destination = vec2.lerp((1 - self.projectileStack[i].lifetime/self.projectileStack[i].maxLifetime)*0.05, self.projectileStack[i].destination, self.projectileStack[i].origin)

    if self.projectileStack[i].lifetime <= 0 then
      table.remove(self.projectileStack, i)
    end
  end

  activeItem.setScriptedAnimationParameter("projectileStack", self.projectileStack)
end


function hitscanLib:fireBeam()
    if world.lineTileCollision(mcontroller.position(), self:firePosition()) then return end
  
    self:startFireLoop()
    if storage.ammo > 0 then
      self:recoil(false, 0.1)
      self:screenShake(self.currentScreenShake * 4)
    end

    animator.setAnimationState("gun", "firingLoop")

    local beamDamageConfig = sb.jsonMerge(self.beamParameters.beamDamageConfig)
  
    local recoilTimer = 0
    local beamTimeout = self.currentCycleTime
    local ammoConsumeTimer = beamTimeout
    local consumedAmmo = false

    local originalStatusEffects = sb.jsonMerge(beamDamageConfig.statusEffects)

    local hitreg = self:hitscan(true)
    local beamStart = hitreg[1]
    local beamEnd = nil
    
    -- loop to maintain beam fire
    while ((self.chargeTime + self.overchargeTime <= 0 or not self.semi)
    and self:triggering()
    or (
      not self:triggering()
      and self.chargeTimer > 0
      and self.semi
    ))
    and (not self.beamParameters.consumeAmmoOverTime or storage.ammo > 0)
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    do

      self.isFiring = true
  
      hitreg = self:hitscan(true)
      beamStart = hitreg[1]
      beamEnd = hitreg[2]
  
      if ammoConsumeTimer >= beamTimeout then
        if self:jam() then break end
        ammoConsumeTimer = 0
        if self.beamParameters.consumeAmmoOverTime or not consumedAmmo then
          self:updateAmmo(-self.ammoPerShot)
          storage.unejectedCasings = storage.unejectedCasings + math.min(storage.ammo, self.ammoPerShot)
          consumedAmmo = true
        end
  
        -- update charge damage multiplier
        if self.overchargeTime > 0 then
          self.chargeDamageMult = 1 + (self.chargeTimer - self.chargeTime)/self.overchargeTime
        end
  
        -- coors for damage poly
        local actualMuzzlePosition = vec2.rotate(
            self.weapon.muzzleOffset,
            self.weapon.relativeWeaponRotation
          )
        local beamLength = world.magnitude(beamStart, beamEnd)
        local actualDamageEnd = vec2.rotate(
          {self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2]},
          self.weapon.relativeWeaponRotation
        )
  
        -- update base damage accordingly
        local multishot = self.projectileCount * self:rollMultishot()
        beamDamageConfig.baseDamage = self:damagePerShot(true) * multishot
      
        if self.critFlag then
          if self.enableMuzzleCritParticles then
            animator.burstParticleEmitter("muzzleCrit")
          end
          beamDamageConfig.statusEffects = sb.jsonMerge(beamDamageConfig.statusEffects, { "project45critdamaged" })
          self.critFlag = false
        else
          beamDamageConfig.statusEffects = sb.jsonMerge(originalStatusEffects)
        end

        -- draw damage poly
        self.weapon:setDamage(
          beamDamageConfig,
          {
            {actualMuzzlePosition[1], actualMuzzlePosition[2] - self.beamParameters.beamWidth / 16},
            {actualMuzzlePosition[1], actualMuzzlePosition[2] + self.beamParameters.beamWidth / 16},
            {actualDamageEnd[1], actualDamageEnd[2] + self.beamParameters.beamWidth / 16},
            {actualDamageEnd[1], actualDamageEnd[2] - self.beamParameters.beamWidth / 16}
          })
      else
        self.weapon:setDamage()
      end
  
  
      -- VFX
  
      self:muzzleFlash(true)
      
      recoilTimer = recoilTimer + self.dt
      if recoilTimer >= 0.1 then
        self:screenShake(self.currentScreenShake, 0.01)
        recoilTimer = 0
      end
      self:recoil(false, self.recoilMult * 0.1)
  
      activeItem.setScriptedAnimationParameter("beamLine", {beamStart, beamEnd})
      activeItem.setScriptedAnimationParameter("beamWidth", self.beamParameters.beamWidth + sb.nrand(self.beamParameters.beamJitter, 0))
      activeItem.setScriptedAnimationParameter("beamInnerWidth", self.beamParameters.beamInnerWidth + sb.nrand(self.beamParameters.beamJitter, 0))
  
      local hitscanActionsOnReap = {
        {
          action="loop",
          count=6,
          body={
            {
              action="particle",
              specification={
                type="ember",
                size=1,
                color=self.beamParameters.beamColor or {255, 255, 200, 255},
                light=self.beamParameters.beamColor or {65, 65, 51},
                fullbright=true,
                destructionTime=0.2,
                destructionAction="shrink",
                fade=0.9,
                initialVelocity={0, 5},
                finalVelocity={0, -50},
                approach={0, 30},
                timeToLive=0,
                layer="middle",
                variance={
                  position={0.25, 0.25},
                  size=0.5,
                  initialVelocity={10, 10},
                  timeToLive=0.2
                }
              }
            }
          }
        }
      }
  
      world.spawnProjectile(
        "invisibleprojectile",
        beamEnd,
        activeItem.ownerEntityId(),
        {0, 1},
        false,
        {
          damageType = "NoDamage",
          power = 0,
          timeToLive = 0,
          actionOnReap = hitscanActionsOnReap
        }
      )
  
      ammoConsumeTimer = ammoConsumeTimer + self.dt
  
      coroutine.yield()
    end
  
    self:stopFireLoop()

    self.isFiring = false
    self.muzzleProjectileFired = false

    hitreg = self:hitscan(true)
    beamEnd = hitreg[2]

    table.insert(self.projectileStack, {
      width = self.beamParameters.beamWidth,
      origin = self:firePosition(),
      destination = beamEnd,
      lifetime = 0.1,
      maxLifetime = 0.1,
      color = {255,255,255}
    })
    animator.setAnimationState("gun", "firing")
  
    activeItem.setScriptedAnimationParameter("beamLine", nil)
    
    if not self.alwaysMaintainCharge and self.resetChargeOnFire then self.chargeTimer = 0 end
    
    if self.beamParameters.ejectCasingsOnBeamEnd then
      self:setState(self.ejecting)
    else
      if storage.ammo <= 0 then
        self.triggered = true
        animator.setAnimationState("chamber", "filled")
      end
    end
    
end

-- Utility function that scans for an entity to damage.
-- @return {hitscan_line_origin, hitscan_line_destination, entity_id[]}
function hitscanLib:hitscan(isLaser, degAdd, scanLength, ignoresTerrain, punchThrough, scanUntilCursor, spread, hitscanLineOrigin, chain)

  -- initialize hitscan parameters
  if self.projectileKind ~= "projectile" then

    scanLength = scanLength or self[self.projectileKind .. "Parameters"].range or 100
    
    if self.chargeTime + self.overchargeTime > 0
    and self.chargeTimer >= self.chargeTime + self.overchargeTime
    then
      punchThrough = punchThrough or self[self.projectileKind .. "Parameters"].fullChargePunchThrough or 0
      ignoresTerrain = ignoresTerrain ~= nil and ignoresTerrain or self[self.projectileKind .. "Parameters"].ignoresTerrainOnFullCharge
    else
      punchThrough = punchThrough or self[self.projectileKind .. "Parameters"].punchThrough or 0
      ignoresTerrain = ignoresTerrain ~= nil and ignoresTerrain or self[self.projectileKind .. "Parameters"].ignoresTerrain
    end

  else

    scanLength = scanLength or 100
    punchThrough = punchThrough or 0

  end

  -- if chain is truthy i.e. the hitscan is for the initial hit of a chain, then punchthrough is set to 0
  punchThrough = chain and 0 or punchThrough

  -- establish origin and scan length
  hitscanLineOrigin = hitscanLineOrigin or self:firePosition()
  if scanUntilCursor then
    scanLength = math.min(world.magnitude(hitscanLineOrigin, activeItem.ownerAimPosition()), scanLength)
  end

  -- using scan length and origin, determine hitscan endpoint
  local hitscanLineDestination = vec2.add(hitscanLineOrigin, vec2.mul(self:aimVector(spread or self.spread or 0, degAdd or 0), scanLength))
  local fullHitscanLineDestination = not ignoresTerrain and world.lineCollision(hitscanLineOrigin, hitscanLineDestination, {"Block", "Dynamic"}) or hitscanLineDestination
  -- chain: {"targeted" | "spread" | nil}

  local hitEntityIds
  hitEntityIds = world.entityLineQuery(hitscanLineOrigin, fullHitscanLineDestination, {
    withoutEntityId = entity.id(),
    includedTypes = {"monster", "npc", "player"},
    order = "nearest"
  })

  local damagedEntityIds = {}
  local penetrated = 0
  
  -- if entities are hit,
  if #hitEntityIds > 0 then
    -- for each entity hit
    for i, id in ipairs(hitEntityIds) do
      if world.entityCanDamage(entity.id(), id)
      and world.entityDamageTeam(id) ~= "ghostly" -- prevents from hitting those annoying floaty things
      then
        -- let hitscan line destination be location of entity
        if chain then
          hitscanLineDestination = world.entityPosition(id)
          table.insert(damagedEntityIds, id)
        else

          -- if regular hitscan, correct the destination
          local aimAngle = vec2.angle(world.distance(hitscanLineDestination, hitscanLineOrigin))
          local entityAngle = vec2.angle(world.distance(world.entityPosition(id), hitscanLineOrigin))
          local rotation = aimAngle - entityAngle
          
          hitscanLineDestination = vec2.rotate(world.distance(world.entityPosition(id), hitscanLineOrigin), rotation)
          hitscanLineDestination = vec2.add(hitscanLineDestination, hitscanLineOrigin)

          table.insert(damagedEntityIds, id)

        end
        penetrated = penetrated + 1
        if penetrated > (punchThrough) then break end
      end
    end
  end

  if penetrated <= punchThrough then hitscanLineDestination = fullHitscanLineDestination end

  return {hitscanLineOrigin, hitscanLineDestination, damagedEntityIds}
end

function hitscanLib:updateLaser()
  if not self.laser.enabled then return
  elseif not self.weapon.reloadFlashLasers and (storage.ammo < 0 or self.weapon.reloadTimer >= 0) then
    activeItem.setScriptedAnimationParameter("primaryLaserEnabled", false)
    return
  end
  if not self:muzzleObstructed() then
    local laser = self:hitscan(
      true,
      nil,
      self.laser.range,
      nil,
      nil,
      self.laser.renderUntilCursor,
      0
    )
    activeItem.setScriptedAnimationParameter("primaryLaserEnabled", not self.performanceMode)
    activeItem.setScriptedAnimationParameter("primaryLaserStart", laser[1])
    activeItem.setScriptedAnimationParameter("primaryLaserEnd", laser[2])
  else
    activeItem.setScriptedAnimationParameter("primaryLaserEnabled", false)
    activeItem.setScriptedAnimationParameter("primaryLaserStart", nil)
    activeItem.setScriptedAnimationParameter("primaryLaserEnd", nil)
  end
end

function hitscanLib:updateSummonAreaIndicator()
  if not (self.laser.enabled or storage.altLaserEnabled) then
    activeItem.setScriptedAnimationParameter("primarySummonArea", nil)
    return
  elseif storage.ammo < 0 or self.weapon.reloadTimer >= 0 then
    activeItem.setScriptedAnimationParameter("primaryLaserEnabled", false)
    activeItem.setScriptedAnimationParameter("primarySummonArea", nil)
    return
  end
  activeItem.setScriptedAnimationParameter("primaryLaserEnabled", not self.performanceMode)
  activeItem.setScriptedAnimationParameter("primarySummonArea", self:summonArea())
  activeItem.setScriptedAnimationParameter("muzzleObstructed", self:muzzleObstructed())
end

function hitscanLib:summonArea()
  return project45util.circle(math.tan(util.toRadians((self.currentInaccuracy or 7.5) + (self.spread or 0.01))) * world.magnitude(activeItem.ownerAimPosition(), mcontroller.position()))
end

--[[
function hitscanLib:summonAreaObstructed()
  local x = world.polyCollision(self:summonArea())
  -- sb.logInfo(sb.printJson(x))
  return x
end
--]]

function hitscanLib:summonPosition()
  local randRotate = math.random() * math.pi * 2
  local randRadius = math.random() * math.tan(util.toRadians((self.currentInaccuracy or 7.5) + (self.spread or 0.01))) * world.magnitude(activeItem.ownerAimPosition(), mcontroller.position())
  randRadius = math.abs(randRadius)
  local randVector = vec2.rotate({randRadius, 0}, randRotate)
  return vec2.add(randVector, activeItem.ownerAimPosition())
end

function hitscanLib:summonVector()
  return vec2.norm(world.distance(self:firePosition(), activeItem.ownerAimPosition()))
end

-- serves as a replacement for Weapon:damageSource
function hitscanLib:alteredDamageSourceFunc(damageConfig, damageArea, damageTimeout)
  if damageArea then
    local knockback = damageConfig.knockback
    if knockback and damageConfig.knockbackDirectional ~= false then
      knockback = knockbackMomentum(damageConfig.knockback, damageConfig.knockbackMode, self.aimAngle, self.aimDirection)
    end
    local damage = damageConfig.baseDamage * self.damageLevelMultiplier

    local damageLine, damagePoly
    if #damageArea == 2 then
      damageLine = damageArea
    else
      damagePoly = damageArea
    end

    return {
      poly = damagePoly,
      line = damageLine,
      damage = damage,
      trackSourceEntity = damageConfig.trackSourceEntity,
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      damageSourceKind = damageConfig.damageSourceKind,
      statusEffects = damageConfig.statusEffects,
      knockback = knockback or 0,
      rayCheck = true,
      damageRepeatGroup = damageRepeatGroup(damageConfig.timeoutGroup),
      damageRepeatTimeout = damageTimeout or damageConfig.timeout
    }
  end
end