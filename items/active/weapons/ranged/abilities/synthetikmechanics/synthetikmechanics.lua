require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"

SynthetikMechanics = WeaponAbility:new()

-- MAIN FUNCTIONS

function SynthetikMechanics:init()

    -- Initial state of gun is empty and unracked.
    self.aimProgress = 0

    -- initialize storage
    storage.ammo = storage.ammo or -1 -- -1 ammo means we don't have a mag in the gun
    storage.reloadRating = storage.reloadRating or "ok"
    storage.jamAmount = storage.jamAmount or 0
    storage.animationState = storage.animationState or {gun = "ejecting", mag = "absent"} -- initial animation state is empty gun
    self:setStance(storage.targetStance or self.stances.aim)

    -- reset non-persistent timers and flags
    self.chargeTimer = 0
    self.muzzleFlashTimer = 0
    self.cooldownTimer = self.fireTime
    self.reloadTimer = -1 -- not reloading
    self.isCharging = false
    self.chamberReady = storage.ammo < 0 -- TODO: should really improve this thing
    
    self.projectileStack = {}

    self.chargeLoopPlaying = false
    animator.stopAllSounds("chargeWhine")
    animator.stopAllSounds("chargeDrone")
    
    -- Just in case the weapon is switched to while holding mouse click
    -- update logic should automatically falsify this otherwise
    self.triggered = true

    -- the weapon is "done" bursting on init
    self.burstCounter = self.burstCount

    -- animation parameters
    activeItem.setScriptedAnimationParameter("reloadTime", self.reloadTime)
    activeItem.setScriptedAnimationParameter("perfectReloadRange", {self.reloadTime * self.perfectReloadInterval[1], self.reloadTime * self.perfectReloadInterval[2]})

    -- initialize visuals

    -- initialize gun animation state
    if storage.jamAmount > 0 then
      storage.animationState["gun"] = "jammed"
    elseif storage.ammo > 0 or storage.animationState["gun"] == "feeding" then
      storage.animationState["gun"] = "idle"
    end

    if storage.ammo >= 0 and self.magType ~= "strip" then
      storage.animationState["mag"] = "present"
    else
      storage.animationState["mag"] = "absent"
    end

    animator.setAnimationState("gun", storage.animationState["gun"])
    animator.setAnimationState("mag", storage.animationState["mag"])
    animator.setLightActive("muzzleFlash", false)
    animator.setAnimationState("flash", "off")
    self.weapon:setStance(self.stances.idle)
end

function SynthetikMechanics:update(dt, fireMode, shiftHeld)

    WeaponAbility.update(self, dt, fireMode, shiftHeld)
    self.weapon:updateAim()
    self:aim()

    self.shiftHeld = shiftHeld

    self:updateScriptedAnimationParameters()
    self:updateSoundProperties()
    self:updateCursor(shiftHeld)
    self:updateProjectileStack()

    -- local laserLine = (self.allowLaser and shiftHeld and storage.ammo > 0) and self:hitscan(true) or {}


    -- increments/decrements
    self.muzzleFlashTimer = math.max(0, self.muzzleFlashTimer - self.dt)
    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    self.aimProgress = math.min(1, self.aimProgress + self.dt / self.aimTime[shiftHeld and 2 or 1])

    -- updating logic

    if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
      self.triggered = false
    end

    -- if firing and cycling don't decrement chargeTimer
    if not self.isCharging and not self.weapon.currentAbility then
      self.chargeTimer = math.max(0, self.chargeTimer - self.dt)
    end

    if self.muzzleFlashTimer <= 0 then
      animator.setLightActive("muzzleFlash", false)
    end

    -- I/O logic
    if self:triggering()
     and not self.weapon.currentAbility
     and self.cooldownTimer == 0 then
      -- if not jammed
      if storage.jamAmount <= 0 then
    
        -- if no mag and fire is not held then reload
        if storage.ammo < 0 and not self.triggered then
          -- sb.logInfo("[PROJECT 45] Entered State: Reloading")
          self:setState(self.reloading)

        -- if chamber is not ready then eject case
        elseif not self.chamberReady and self:canTrigger() and self.manualFeed then
          -- sb.logInfo("[PROJECT 45] Entered State: Ejecting Case")
          self:setState(self.ejectingCase)
  
        -- if no ammo and fire is not held then eject mag
        elseif storage.ammo == 0 and not self.triggered then
          -- sb.logInfo("[PROJECT 45] Entered State: Ejecting Mag")
          self:ejectMag()

        -- if has ammo then fire
        elseif storage.ammo > 0 then
          -- sb.logInfo("[PROJECT 45] Entered State: Charging")
          self:setState(self.charging)

        end
      
      -- if jammed
      else
        
        if not self.triggered then self:setState(self.unjam) end
      
      end

      self.cooldownTimer = self.fireTime
    end
end

function SynthetikMechanics:uninit()
end

-- STATES

-- charging is driven by user input
-- [CHARGING] -> FIRING -> EJECTING CASE -> FEEDING
function SynthetikMechanics:charging()

  self:setStance(self.stances.aim)

  -- if it can fire then begin charging
  if self:canTrigger() then
    self.triggered = true

    if self:jam() then return end -- attempt to jam

    -- If there's no charge time then don't waste cpu cycles doing a pointless loop
    if self.chargeTime <= 0 then self:setState(self.firing) return end

    self:setAnimationState("gun", "charging")

    self.isCharging = true
    if not self.chargeLoopPlaying then
      animator.playSound("chargeDrone", -1)
      animator.playSound("chargeWhine", -1)
      self.chargeLoopPlaying = true
    end
    while self:triggering() do

      -- TODO: play charging sound
      self.chargeTimer = self.chargeTimer + self.dt
      coroutine.yield()

      -- automatically transist to firing state when fully charged
      if self.autoFireAfterCharge and self.chargeTimer >= self.chargeTime then
        break
      end
    end

    if self.chargeTimer >= self.chargeTime then
      self:setState(self.firing)
    end
    
    self.isCharging = false
    animator.setAnimationState("gun", "idle")
  end

end

-- firing happens automatically after charging (if fully charged or if there's no charge time)
-- CHARGING -> [FIRING] -> EJECTING CASE -> FEEDING
function SynthetikMechanics:firing()
  self.triggered = true

  -- don't fire when muzzle collides with terrain
  if world.lineTileCollision(mcontroller.position(), self:firePosition()) then return end

  if self.semi then self.chargeTimer = 0 end
  -- if weapon has just fully bursted, reset burst counter 
  if self.burstCounter >= self.burstCount then
    self.burstCounter = 0
  end

  -- fire projectile
  if self.projectileType == "hitscan" then
    self:fireHitscan()
  else
    self.fireProjectile()
  end

  -- bullet fired, chamber is now unready
  self.chamberReady = false

  -- muzzle flash
  self:flashMuzzle()
  self:setAnimationState("gun", "firing")

  -- increment burst counter
  self.burstCounter = self.burstCounter + 1

  -- decrement ammo
  storage.ammo = storage.ammo - self.ammoPerShot
  
  -- if manual feed e.g. bolt-action, exit state; otherwise, transist to next state
  if not self.manualFeed then
    self:setState(self.ejectingCase)
    return
  else
    self.cooldownTimer = self.fireTime
    return
  end

end

-- ejecting can be driven by user input
-- CHARGING -> FIRING -> [EJECTING CASE] -> FEEDING
function SynthetikMechanics:ejectingCase()

  -- if casings are kept (e.g. break-action, fixed-magazine revolvers)
  if self.keepCasings then
    util.wait(self.cycleTime/2) -- maintain fire rate

    if storage.ammo > 0 then
      self:setState(self.feeding) -- immediately transist
    end
    -- gun doesn't visually eject
    return
  end

  -- if manual feed and can "fire" then eject case
  if (self.manualFeed and self:canTrigger()) or not self.manualFeed then
    self.triggered = true
      
    -- eject projectile
    -- TODO: spawn bullet case particle
    if self.manualFeed then animator.playSound("boltPull") end
    animator.burstParticleEmitter("ejectionPort")
    self:setAnimationState("gun", "ejecting")
    self.chamberReady = false

    -- if no ammo left in clip magazine, eject clip magazine (like with the m1 garand)
    if self.magType == "clip" and storage.ammo == 0 then
      animator.playSound("ping")
      self:ejectMag()
    end
    util.wait((self.manualFeed and self.cockTime or self.cycleTime)/2)


        -- transist state if there's ammo left
        -- otherwise, exit loop
    if storage.ammo > 0 then self:setState(self.feeding) end

    return
  end
end

-- happens automatically; inserts catridge into gun breech
-- CHARGING -> FIRING -> EJECTING CASE -> [FEEDING]
function SynthetikMechanics:feeding()
  
  -- vfx, delays and updates chamber status
  if self.manualFeed then animator.playSound("boltPush") end
  self:setAnimationState("gun", "feeding")
  util.wait((self.manualFeed and self.cockTime or self.cycleTime)/2)
  self:setAnimationState("gun", "idle")
  self.chamberReady = true

  if self.burstCounter < self.burstCount then
    self:setState(self.firing)
  end

end

-- done after magazine is absent
function SynthetikMechanics:reloading()
  self.triggered = true

  if status.overConsumeResource("energy", self.reloadEnergyCostRate*status.resourceMax("energy")) then
    
    self.chargeTimer = 0
    self.isCharging = false
    
    self:setAnimationState("mag", "present") -- insert mag
    animator.playSound("click")
    
    -- RELOAD MINIGAME  
    self.weapon:setStance(self.stances.reloading)
    self.reloadTimer = 0 -- begin minigame
    local reloadAttempted = false
    storage.reloadRating = "ok"
    -- Possible TODO: randomize reload times
    -- activeItem.setScriptedAnimationParameter("perfectReloadRange", {self.reloadTime * self.perfectReloadInterval[1], self.reloadTime * self.perfectReloadInterval[2]})
    while self.reloadTimer < self.reloadTime do

      activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)
      activeItem.setScriptedAnimationParameter("reloadRating", storage.reloadRating)

      self.reloadTimer = self.reloadTimer + self.dt

      if self:triggering() and not self.triggered and not reloadAttempted then
        reloadAttempted = true
        if self.reloadTime * self.perfectReloadInterval[1] <= self.reloadTimer and self.reloadTimer <= self.reloadTime * self.perfectReloadInterval[2] then
          animator.playSound("ping")
          storage.reloadRating = "good"
          break
        else
          animator.playSound("click")
          storage.reloadRating = "bad"
        end
      end
      
      coroutine.yield()

    end
    self.weapon:setStance(self.stances.reloaded)

    -- replenish ammo
    storage.ammo = self.maxAmmo
    self.burstCounter = self.burstCount

    if self.magType == "strip" then
      animator.setAnimationState("mag", "absent")
      animator.burstParticleEmitter("magazine")
    end

    -- cock gun
    self:setState(self.cocking)

    self:setStance(self.stances.aim)

  end

end

function SynthetikMechanics:cocking()
  if animator.animationState("gun") ~= "ejecting" then
    animator.playSound("boltPull")
    self:setAnimationState("gun", "ejecting")
    util.wait(self.cockTime/3)
  end
  self:setAnimationState("gun", "feeding")
  util.wait(self.cockTime/3)

  self.reloadTimer = -1 -- end minigame

  animator.playSound("boltPush")
  self:setAnimationState("gun", "idle")
  util.wait(self.cockTime/3)
  self.burstCounter = self.burstCount
  self.chamberReady = true
end

-- ACTIONS

-- triggered by player input
function SynthetikMechanics:ejectMag()
  self.triggered = true
  if self.keepCasings then
    animator.setParticleEmitterBurstCount("ejectionPort", self.maxAmmo)
    animator.burstParticleEmitter("ejectionPort")
  else
    animator.burstParticleEmitter("magazine")
  end
  animator.playSound("reloadStart")
  self:setAnimationState("mag", "absent")
  if self.magType == "default" then self:snapStance(self.stances.ejectmag) end
  storage.ammo = -1
end

function SynthetikMechanics:fireProjectile()

end

function SynthetikMechanics:fireHitscan()
  for i = 1, self.projectileCount do
    --[[
    if world.lineTileCollision(mcontroller.position(), self:firePosition()) then
      goto next_projectile
    end
    --]]

  
    -- scan hit down range
    -- hitreg[2] is where the bullet trail terminates,
    -- hitreg[3] is the array of hit entityIds
    local hitReg = self:hitscan()

    -- if damageable entity has been detected (hitreg[3] is not nil), damage it
    if #hitReg[3] > 0 then
      for _, hitId in ipairs(hitReg[3]) do
        world.sendEntityMessage(hitId, "applyStatusEffect", "project45damage", self:damagePerShot(), entity.id()) -- TODO: duplicate and rename damage status effect
      end
    end

    -- bullet trail info inserted to projectile stack that's being passed to the animation script
    -- each bullet trail in the stack is rendered, and the lifetime is updated in this very script too
    local life = self.projectileParams.fadeTime or 0.5
    table.insert(self.projectileStack, {
      width = self.projectileParams.hitscanWidth,
      origin = hitReg[1],
      destination = hitReg[2],
      lifetime = life,
      maxLifetime = life
    })

    -- hitscan explosion vfx
    world.spawnProjectile(
      "project45_hitexplosion", -- TODO: duplicate and rename this explosion
      hitReg[2],
      activeItem.ownerEntityId(),
      self:aimVector(3.14),
      false,
      {}
    )

  end
end

-- Utility function that scans for an entity to damage.
  function SynthetikMechanics:hitscan(isLaser)

    local scanOrig = self:firePosition()
  
    local scanDest = vec2.add(scanOrig, vec2.mul(vec2.rotate(self:aimVector(isLaser and 0 or self.inaccuracy),(self.weapon.relativeArmRotation + self.weapon.relativeWeaponRotation) * mcontroller.facingDirection()), self.projectileParams.range or 100))
    scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest
  
    -- hitreg
    local hitId = world.entityLineQuery(scanOrig, scanDest, {
      withoutEntityId = entity.id(),
      includedTypes = {"monster", "npc", "player"},
      order = "nearest"
    })
  
    local eid = {}
    local pen = 0
    if #hitId > 0 then
      for i, id in ipairs(hitId) do
        if world.entityCanDamage(entity.id(), id) then
  
          local aimAngle = vec2.angle(world.distance(scanDest, scanOrig))
          local entityAngle = vec2.angle(world.distance(world.entityPosition(id), scanOrig))
          local rotation = aimAngle - entityAngle
          
          scanDest = vec2.rotate(world.distance(world.entityPosition(id), scanOrig), rotation)
          scanDest = vec2.add(scanDest, scanOrig)
  
          table.insert(eid, id)
  
          pen = pen + 1
  
          if pen > (self.projectileParams.punchThrough or 0) then break end
        end      
      end
    end
    
    world.debugLine(scanOrig, scanDest, {255,0,255})
  
    return {scanOrig, scanDest, eid}
  end

function SynthetikMechanics:aim()
  if self.reloadTimer < 0 then
    local stance = storage.targetStance
    if self.aimProgress == 1 then activeItem.setRecoil(true) end
    activeItem.setFrontArmFrame(stance.frontArmFrame)
    activeItem.setBackArmFrame(stance.backArmFrame)
    if config.getParameter("twoHanded", false) then activeItem.setTwoHandedGrip(stance.twoHanded or false) end
    self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
    self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeWeaponRotation), stance.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeArmRotation), stance.armRotation))
  end
end

function SynthetikMechanics:flashMuzzle()

  self:recoil()
  animator.setSoundPitch("fire", sb.nrand(0.01, 1))
  animator.setSoundVolume("hollow", 1 - storage.ammo/self.maxAmmo)

  animator.playSound("fire")
  animator.playSound("hollow")
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.burstParticleEmitter("muzzleFlash")
  animator.setLightActive("muzzleFlash", true)
  animator.setAnimationState("flash", "flash")
  self.muzzleFlashTimer = self.muzzleFlashTime
end

function SynthetikMechanics:recoil()
  self:screenShake()
  activeItem.setRecoil(true)

  local inaccuracy = math.rad(self.recoilDeg[self.shiftHeld and 2 or 1])
  
  self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + inaccuracy
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + inaccuracy

  self.aimProgress = 0

  if self.recoilMomentum then
    mcontroller.addMomentum(vec2.mul(self:aimVector(), self.recoilMomentum * -1))
  end

end

function SynthetikMechanics:unjam()
  if not self.triggered then
    self.triggered = true
    self:setAnimationState("gun", "unjam")
    animator.playSound("unjam")
    self:setStance(self.stances.jammed)
    self:snapStance(self.stances.unjam)
    storage.jamAmount = math.max(0, storage.jamAmount - self.unjamAmount)
    if storage.jamAmount > 0 then
      util.wait(self.unjamTime)
      self:setAnimationState("gun", "jammed")
    else
      storage.reloadRating = "ok"
      animator.burstParticleEmitter("ejectionPort")
      self:setState(self.cocking)
      self:setStance(self.stances.aim)
    end
  end
end

-- UPDATE FUNCTIONS

function SynthetikMechanics:updateScriptedAnimationParameters()

  -- display
  activeItem.setScriptedAnimationParameter("ammoDisplay",
    storage.jamAmount > 0 and "J" or
    self.reloadTimer >= 0 and "R" or
    storage.ammo >= 0 and tostring(storage.ammo) or
    "E"
  )
  activeItem.setScriptedAnimationParameter("gunHand", activeItem.hand())
  activeItem.setScriptedAnimationParameter("aimPosition", activeItem.ownerAimPosition())
  activeItem.setScriptedAnimationParameter("playerPos", mcontroller.position())

  activeItem.setScriptedAnimationParameter("jamAmount", storage.jamAmount)
  
end

function SynthetikMechanics:updateSoundProperties()
  animator.setSoundVolume("chargeDrone", 0.25 + 0.7 * self.chargeTimer / self.chargeTime)
  animator.setSoundPitch("chargeWhine", 1 + 0.3 * self.chargeTimer / self.chargeTime)
  animator.setSoundVolume("chargeWhine", 0.25 + 0.75 * self.chargeTimer / self.chargeTime)
  if self.chargeTimer == 0 then
    animator.stopAllSounds("chargeWhine")
    animator.stopAllSounds("chargeDrone")
    self.chargeLoopPlaying = false
  end
end

function SynthetikMechanics:updateCursor(shiftHeld)
  if shiftHeld then
    activeItem.setCursor("/cursors/project45reticle.cursor")
  else
    activeItem.setCursor("/cursors/project45reticlerun.cursor")
  end
end

function SynthetikMechanics:updateProjectileStack()

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

-- HELPER FUNCTIONS

function SynthetikMechanics:damagePerShot()
  return self.baseDamage * activeItem.ownerPowerMultiplier() / self.projectileCount
end

function SynthetikMechanics:screenShake(amount, shakeTime)
    local shake_dir = vec2.mul(self:aimVector(0), -1 * (amount or 0.1))
    local cam = world.spawnProjectile(
      "invisibleprojectile",
      vec2.add(mcontroller.position(), shake_dir),
      0,
      {0, 0},
      false,
      {
        power = 0,
        timeToLive = shakeTime or 0.01,
        damageType = "NoDamage"
      }
    )
    activeItem.setCameraFocusEntity(cam)
end

function SynthetikMechanics:firePosition()
    return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
  end

function SynthetikMechanics:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand((inaccuracy or 0), 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function SynthetikMechanics:canTrigger()
  -- attempt jam; if jammed, set jamAmount to 1 then return false
  return (self.semi and not self.triggered) or not self.semi
end

function SynthetikMechanics:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function SynthetikMechanics:jam()
  if self:diceRoll() < self.jamChances[storage.reloadRating] then
    storage.ammo = storage.ammo - self.ammoPerShot
    self.chargeTimer = 0
    self.isCharging = false
    storage.jamAmount = 1
    animator.playSound("jammed")
    self:setAnimationState("gun", "jammed")
    return true
  end
  return false
end

function SynthetikMechanics:diceRoll()
  math.randomseed(math.floor(sb.nrand(5, os.time()))) -- set random seed with sb.nrand, mean = epoch time, stdev = 5
  local diceRoll = math.random()
  -- sb.logInfo("[PROJECT 45] Dice Rolled: " .. diceRoll)
  return diceRoll -- function like orig function
end

function SynthetikMechanics:setAnimationState(part, state)
  animator.setAnimationState(part, state)
  storage.animationState[part] = state
end

function SynthetikMechanics:setStance(stance)
  storage.targetStance = copy(stance)
  self.aimProgress = 0
end

function SynthetikMechanics:snapStance(stance)
  self.weapon:setStance(stance)
  self.aimProgress = 0
end