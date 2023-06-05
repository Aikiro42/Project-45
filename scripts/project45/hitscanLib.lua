require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"

hitscanLib = {}

-- replaces fireProjectile
function hitscanLib:fireHitscan(projectileType)

    -- scan hit down range
    -- hitreg[1] is where the bullet trail emanates,
    -- hitreg[2] is where the bullet trail terminates
    local hitReg = self:hitscan(false)
    local crit = self:crit()
    local finalDamage = self:damagePerShot(true) * crit
    local damageConfig = {
      -- we included activeItem.ownerPowerMultiplier() in
      -- self:damagePerShot() so we cancel it
      baseDamage = finalDamage,
      timeout = self.currentCycleTime,
      damageSourceKind = crit > 1 and "project45-critical" or nil
    }

    damageConfig = sb.jsonMerge(damageConfig, self.hitscanParameters.hitscanDamageConfig or {})
    
    -- coordinates are based off mcontroller position
    self.weapon:setOwnerDamageAreas(damageConfig, {{
      vec2.sub(hitReg[1], mcontroller.position()),
      vec2.sub(hitReg[2], mcontroller.position())
    }})

    -- bullet trail info inserted to projectile stack that's being passed to the animation script
    -- each bullet trail in the stack is rendered, and the lifetime is updated in this very script too
    local life = self.hitscanParameters.hitscanFadeTime or 0.5
    table.insert(self.projectileStack, {
      width = self.hitscanParameters.hitscanWidth,
      origin = hitReg[1],
      destination = hitReg[2],
      lifetime = life,
      maxLifetime = life,
      color = self.hitscanParameters.hitscanColor
    })

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
    
    -- sb.logInfo(self.projectileParameters.hitregPower)
    world.spawnProjectile(
      "invisibleprojectile",
      hitReg[2],
      activeItem.ownerEntityId(),
      self:aimVector(3.14),
      false,
      {
        damageType = "NoDamage",
        power = finalDamage,
        timeToLive = 0,
        actionOnReap = hitscanActionsOnReap
      }
    )
    --]]

end

function hitscanLib:updateProjectileStack()

  -- update projectile stack
  for i, projectile in ipairs(self.projectileStack) do
    self.projectileStack[i].lifetime = self.projectileStack[i].lifetime - self.dt

    -- LERPing; the commented lines work, but they kinda don't look good.
    -- Still leaving it here just in case I feel like reincluding it.
    self.projectileStack[i].origin = vec2.lerp((1 - self.projectileStack[i].lifetime/self.projectileStack[i].maxLifetime)*0.01, self.projectileStack[i].origin, self.projectileStack[i].destination)
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
  
    local beamDamageConfig = sb.jsonMerge(self.beamParameters.beamDamageConfig)
  
    local recoilTimer = 0
    local beamTimeout = self.currentCycleTime
    local ammoConsumeTimer = beamTimeout
    local fireEndBeamEnd = nil
  
    while self:triggering()
    and storage.ammo > 0
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    do
  
      self.beamFiring = true
  
      local hitreg = self:hitscan(true)
      local beamStart = hitreg[1]
      local beamEnd = hitreg[2]
  
      if ammoConsumeTimer >= beamTimeout then
        -- TODO: if self:jam() then break end
        ammoConsumeTimer = 0
        self:updateAmmo(-self.ammoPerShot)
        storage.unejectedCasings = storage.unejectedCasings + math.min(storage.ammo, self.ammoPerShot)
  
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
        local crit = self:crit()
        beamDamageConfig.baseDamage = self:damagePerShot(true) * crit

        -- beamDamageConfig.damageSourceKind = crit > 1 and "project45-critical" or self.beamParameters.beamDamageConfig.damageSourceKind
        -- beamDamageConfig.damageType = crit > 1 and "IgnoresDef" or nil
  
        -- draw damage poly
        self.weapon:setDamage(
          beamDamageConfig,
          {
            {actualMuzzlePosition[1], actualMuzzlePosition[2] - self.beamParameters.beamWidth / 16},
            {actualMuzzlePosition[1], actualMuzzlePosition[2] + self.beamParameters.beamWidth / 16},
            {actualDamageEnd[1], actualDamageEnd[2] + self.beamParameters.beamWidth / 16},
            {actualDamageEnd[1], actualDamageEnd[2] - self.beamParameters.beamWidth / 16}
          },
          0)
      else
        self.weapon:setDamage()
      end
  
  
      -- VFX
  
      self:muzzleFlash(true)
      animator.setAnimationState("gun", "firing")
      recoilTimer = recoilTimer + self.dt
  
      if recoilTimer >= 0.05 then
        self:screenShake()
        recoilTimer = 0
      end
      self:recoil(false, 0.1)
  
      fireEndBeamEnd = beamEnd
  
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
  
    if world.lineTileCollision(mcontroller.position(), self:firePosition()) then
      self:stopFireLoop()
    end
  
    self.beamFiring = false
  
    table.insert(self.projectileStack, {
      width = self.beamParameters.beamWidth,
      origin = self:firePosition(),
      destination = fireEndBeamEnd,
      lifetime = 0.1,
      maxLifetime = 0.1,
      color = {255,255,255}
    })
  
    activeItem.setScriptedAnimationParameter("beamLine", nil)
    
    if not self.alwaysMaintainCharge and self.resetChargeAfterFire then self.chargeTimer = 0 end
  
    self:setState(self.ejecting)
    
end

-- Utility function that scans for an entity to damage.
function hitscanLib:hitscan(isLaser)

  local scanOrig = self:firePosition()
  local hitscanRange = isLaser and self.beamParameters.beamLength or self.hitscanParameters.hitscanRange or 100
  local ignoresTerrain = isLaser and self.beamParameters.beamIgnoresTerrain or self.hitscanParameters.hitscanIgnoresTerrain
  local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(isLaser and 0 or self.spread), hitscanRange))
  local fullScanDest = not ignoresTerrain and world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest

  local punchThrough = isLaser and self.beamParameters.beamPunchThrough or self.hitscanParameters.hitscanPunchThrough or 0

  -- hitreg
  local hitId = world.entityLineQuery(scanOrig, fullScanDest, {
    withoutEntityId = entity.id(),
    includedTypes = {"monster", "npc", "player"},
    order = "nearest"
  })

  local eid = {}
  local penetrated = 0

  -- if entities are hit,
  if #hitId > 0 then
    -- for each entity hti
    for i, id in ipairs(hitId) do
      if world.entityCanDamage(entity.id(), id)
      and world.entityDamageTeam(id) ~= "ghostly" -- prevents from hitting those annoying floaty things
      then
        -- let scan destination be location of entity and correct it
        local aimAngle = vec2.angle(world.distance(scanDest, scanOrig))
        local entityAngle = vec2.angle(world.distance(world.entityPosition(id), scanOrig))
        local rotation = aimAngle - entityAngle
        
        scanDest = vec2.rotate(world.distance(world.entityPosition(id), scanOrig), rotation)
        scanDest = vec2.add(scanDest, scanOrig)

        table.insert(eid, id)

        penetrated = penetrated + 1

        if penetrated > (punchThrough) then break end
      end
    end
  end

  if penetrated <= punchThrough then scanDest = fullScanDest end
  
  -- world.debugLine(scanOrig, scanDest, {255,0,255})

  return {scanOrig, scanDest, eid}
end
