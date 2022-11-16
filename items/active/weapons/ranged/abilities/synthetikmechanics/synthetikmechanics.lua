require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/ranged/gunfire.lua"

SynthetikMechanics = GunFire:new()
-- SynthetikMechanics = WeaponAbility:new()

-- MAIN FUNCTIONS

function SynthetikMechanics:init()

    -- Initial state of gun is empty and unracked.
    self.aimProgress = 0

    -- initialize storage
    storage.ammo = storage.ammo or -1 -- -1 ammo means we don't have a mag in the gun
    storage.reloadRating = storage.reloadRating or "ok"
    storage.jamAmount = storage.jamAmount or 0
    storage.animationState = storage.animationState or {gun = "ejecting", mag = "absent"} -- initial animation state is empty gun
    storage.isLaserOn = storage.isLaserOn or false
    -- sb.logInfo("[PROJECT 45] chamber ready? " .. sb.printJson(storage.chamberReady))
    sb.logInfo("[PROJECT 45] World threat level: " .. world.threatLevel())

    storage.chamberReady = storage.chamberReady or storage.ammo <= 0
    storage.dodgeCooldownTimer = storage.dodgeCooldownTimer or 0
    self:setStance(storage.targetStance or self.stances.aim)

    -- DEBUG - Critical Statistics
    storage.critStats = storage.critStats or {
      crits = 0,
      shots = 0
    }

    -- reset non-persistent timers and flags
    self.currentScreenShake = self.screenShakeAmount[1]
    self.chargeTimer = 0
    self.muzzleFlashTimer = 0
    self.muzzleSmokeTimer = 0
    self.dashCooldownTimer = 0
    self.dashTriggerTimer = -1
    self.laserToggleTimer = -1
    self.chargeDamageMult = 1
    self.cooldownTimer = self.fireTime
    self.reloadTimer = -1 -- not reloading
    self.isCharging = false
    -- storage.chamberReady = storage.ammo < 0 -- TODO: should really improve this thing
    self.jamChances.perfect = 0

    -- validations
    self.bulletsPerReload = math.min(self.maxAmmo, self.bulletsPerReload)

    self.projectileParameters = self.projectileParameters or {}

    self.projectileStack = {}

    self.chargeLoopPlaying = false
    animator.stopAllSounds("chargeWhine")
    animator.stopAllSounds("chargeDrone")
    
    -- Just in case the weapon is switched to while holding mouse click
    -- update logic should automatically falsify this otherwise
    self.triggered = true

    -- the weapon is "done" bursting on init
    self.burstCounter = self.burstCount

    -- one-time initialized animation parameters
    activeItem.setScriptedAnimationParameter("reloadTime", self.reloadTime)
    activeItem.setScriptedAnimationParameter("goodReloadRange", {self.reloadTime * self.goodReloadInterval[1], self.reloadTime * self.goodReloadInterval[2]})
    activeItem.setScriptedAnimationParameter("perfectReloadRange", {self.reloadTime * self.perfectReloadInterval[1], self.reloadTime * self.perfectReloadInterval[2]})
    activeItem.setScriptedAnimationParameter("ammoMax", self.maxAmmo)
    activeItem.setScriptedAnimationParameter("muzzleSmokeTime", self.muzzleSmokeTime)
    activeItem.setScriptedAnimationParameter("laserColor", self.laser.color)

    -- debug
    -- animator.setParticleEmitterActive("ejectionPort", true)
    -- animator.setParticleEmitterActive("magazine", true)

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
    activeItem.setScriptedAnimationParameter("muzzleFlash", false)
    animator.setAnimationState("flash", "off")
    self.weapon:setStance(self.stances.idleneo)

    -- necessary updates
    self:updateScriptedAnimationParameters()

end

function SynthetikMechanics:update(dt, fireMode, shiftHeld)

    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    -- ENABLE THESE LINES TO APPROXIMATE OFFSETS
    if self.DEBUG then
      animator.burstParticleEmitter("ejectionPort")
      animator.burstParticleEmitter("magazine")
    end

    self.weapon:updateAim()
    self:aim()

    self.shiftHeld = shiftHeld

    self:updateScriptedAnimationParameters()
    self:updateMagAnimation()
    self:updateSoundProperties()
    self:updateCursor(shiftHeld)
    self:updateProjectileStack()
    self:drawLaser()

    -- local laserLine = (self.allowLaser and shiftHeld and storage.ammo > 0) and self:hitscan(true) or {}


    -- increments/decrements
    self.muzzleFlashTimer = math.max(0, self.muzzleFlashTimer - self.dt)
    self.muzzleSmokeTimer = math.max(0, self.muzzleSmokeTimer - self.dt)
    self.dashCooldownTimer = math.max(0, self.dashCooldownTimer - self.dt)
    self.currentScreenShake = math.max(self.screenShakeAmount[1],
      self.currentScreenShake - self.dt * self.screenShakeDelta[1] * (self.screenShakeAmount[2] - self.screenShakeAmount[1])
    )
    storage.dodgeCooldownTimer = math.max(0, storage.dodgeCooldownTimer - self.dt)
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

    -- turn off muzzleflash automatically
    if self.muzzleFlashTimer <= 0 then
      animator.setLightActive("muzzleFlash", false)
      activeItem.setScriptedAnimationParameter("muzzleFlash", false)
    end

    -- if chargeTimer is up and gun is charging, set animation state of gun to idle
    if self.chargeTimer <= 0 and animator.animationState("gun") == "charging" then
      sb.logInfo("[PROJECT 45] chargeTimer <= 0 and gun is charging; switching animation state to idle")
      self:setAnimationState("gun", "idle")
    end

    if storage.ammo <= 0 and self.chargeTimer > 0 then
      self:setAnimationState("gun", "charging")
    end

    -- Prevent energy regen if there is energy or if currently reloading
    if storage.ammo > 0 or self.reloadTimer > 0 then status.setResource("energyRegenBlock", 1.0) end
    if self.weapon.currentAbility then
      self.dashTriggerTimer = -1
    end
    -- Walk I/O logic
    if shiftHeld then
      
      -- begin Dash Trigger Timer when not in ability
      -- and can dash
      if not self.weapon.currentAbility and storage.dodgeCooldownTimer == 0  then
        if self.dashTriggerTimer < 0 then
          self.dashTriggerTimer = 0 -- set trigger timer
        end
        self.dashTriggerTimer = self.dashTriggerTimer + self.dt
      end

      -- if laser is toggled
      if self.laser.enabled then
        if self.laser.toggle then
          -- set and start the toggle timer
          if self.laserToggleTimer < 0 then
            self.laserToggleTimer = 0
          end
          self.laserToggleTimer = self.laserToggleTimer + self.dt
        
        -- if laser is held instead, turn it on
        else
          if not storage.isLaserOn then animator.playSound("laser") end
          storage.isLaserOn = true
        end
      end
    

    else
      -- if triggered dash, dash when weapon isn't doing an ability
      -- and can dash
      if not self.weapon.currentAbility and storage.dodgeCooldownTimer == 0 then
        if self.dashTriggerTimer <= self.dashParams.triggerTime and self.dashTriggerTimer >= 0 then
          storage.dodgeCooldownTimer = self.dashParams.cooldown
          self:setState(self.dash)
        end
        self.dashTriggerTimer = -1 -- reset trigger timer
      end

      -- if laser is toggled,
      if self.laser.enabled then
        if self.laser.toggle then
          -- if the toggle timer was set and is below the toggle time, toggle laser
          if self.laserToggleTimer <= self.laser.toggleTime and self.laserToggleTimer >= 0 then
            storage.isLaserOn = not storage.isLaserOn
            if storage.isLaserOn then animator.playSound("laser") end
          end
          -- reset the timer
          self.laserToggleTimer = -1
        
        -- if laser is held instead, turn it off
        else
          storage.isLaserOn = false
        end
      end
    
    end

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
        elseif not storage.chamberReady and self:canTrigger() and storage.ammo > 0 --[[and self.manualFeed]] then
          -- sb.logInfo("[PROJECT 45] Entered State: Ejecting Case")
          self:setState(self.ejectingCase)
  
        -- if no ammo and fire is not held then eject mag
        elseif storage.ammo == 0 and not self.triggered then
          -- sb.logInfo("[PROJECT 45] Entered State: Ejecting Mag")
          if self.magType == "strip" then self:setState(self.reloading) else self:ejectMag() end

        -- if has ammo then fire
        elseif storage.ammo > 0 then
          -- sb.logInfo("[PROJECT 45] Entered State: Charging")
          self:setState(self.charging)

        end
      
      -- if jammed
      else
        
        if not self.triggered then self:setState(self.unjam) end
      
      end

      self.cooldownTimer = storage.jamAmount == 0 and self.fireTime or self.unjamTime
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
      self.chargeTimer = math.min(self.chargeTime + self.overchargeTime, self.chargeTimer + self.dt)
      coroutine.yield()

      -- automatically transist to firing state when fully charged/overcharged
      if self.autoFireAfterCharge and
      self.chargeTimer >= (self.chargeTime + self.overchargeTime)
      then
        break
      end
    end
    
    -- condition prevents dividing by zero
    if self.overchargeTime > 0 then
      self.chargeDamageMult = 1 + (self.chargeTimer - self.chargeTime)/self.overchargeTime
    end

    if self.chargeTimer >= self.chargeTime then
      if self.resetChargeAfterFire then self.chargeTimer = 0 end
      self:setState(self.firing)
    end
    self.isCharging = false

    if self.chargeTimer <= 0 then
      self:setAnimationState("gun", "idle")
    end
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

  local projectileType = self.projectileType
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  -- fire projectile
  -- if projectileType == "hitscan" then
  if (projectileType == "project45stdbullet" and not self.overrideHitscan) or projectileType == "hitscan" then
    self:fireHitscan(projectileType)
  else
    self:fireProjectileNeo(projectileType)
  end

  -- bullet fired, chamber is now unready
  storage.chamberReady = false
  self.chargeDamageMult = 1

  -- muzzle flash
  self:muzzleFlash()
  self:setAnimationState("gun", "firing")

  -- update screenShakeAmount
  self.currentScreenShake = math.min(self.screenShakeAmount[2],
    self.currentScreenShake + self.screenShakeDelta[2] * (self.screenShakeAmount[2] - self.screenShakeAmount[1])
  )

  -- increment burst counter
  self.burstCounter = self.burstCounter + 1

  -- decrement ammo
  if self:willConsumeAmmo() then
    storage.ammo = storage.ammo - math.min(self.ammoPerShot, storage.ammo)
  end
  
  -- if manual feed e.g. bolt-action, exit state; otherwise, transist to next state


  if not self.manualFeed or self.burstCounter < self.burstCount then
    -- TEST
    util.wait(self.cycleTime/3)
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
  
  -- sb.logInfo("[PROJECT 45] Entered state: ejectingCase")
  
  -- if casings are kept (e.g. break-action, fixed-magazine revolvers)
  if self.keepCasings then
    -- sb.logInfo("[PROJECT 45] Casings kept; waiting cycle time")
    util.wait(self.cycleTime/3) -- maintain fire rate

    if storage.ammo > 0 then
      self:setState(self.feeding) -- immediately transist
    else
      self:setState(self.whirring) -- see state function for specific conditions
    end
    -- gun doesn't visually eject
    return
  end

  -- if manual feed and can "fire" then eject case
  if (self.manualFeed and self:canTrigger()) or not self.manualFeed or self.burstCounter < self.burstCount then
    -- sb.logInfo("[PROJECT 45] Entering if block")

    self.triggered = true
      
    if self.manualFeed and self.burstCounter >= self.burstCount then
      self:snapStance(self.stances.manualFeed)
      animator.playSound("boltPull")
    end
    
    -- eject projectile
    animator.burstParticleEmitter("ejectionPort")
    self:setAnimationState("gun", "ejecting")
    storage.chamberReady = false

    -- if no ammo left,
    if storage.ammo == 0 then
      -- if it's manual feed and not a clip mag, wait for a bit
      if self.manualFeed and self.magType ~= "clip" then
        -- sb.logInfo("[PROJECT 45] Manual-fed and non-clip mag; waiting cock time")
        util.wait(self.cockTime/2)
      end
      -- if it's a clip mag, immediately eject
      if self.magType == "clip" or self.manualFeed then
        self:ejectMag()
      end
      -- do nothing otherwise
    end

    local waitTime = 0
    if self.manualFeed and self.burstCounter >= self.burstCount then
      -- sb.logInfo("[PROJECT 45] Manual-fed and burstCounter >= burstCount; waiting cock time")
      waitTime = self.cockTime/2
    else
      -- sb.logInfo("[PROJECT 45] Not Manual-fed or burstCounter < burstCount; waiting cycle time")
      waitTime = self.cycleTime/3
    end
    util.wait(waitTime)


    -- transist state if there's ammo left
    if storage.ammo > 0 then
      self:setState(self.feeding)
    
    -- see state function for specific conditions
    else
      self:setState(self.whirring)
    end

    return
  end
end

-- happens automatically; inserts catridge into gun breech
-- CHARGING -> FIRING -> EJECTING CASE -> [FEEDING]
function SynthetikMechanics:feeding()
  -- sb.logInfo("[PROJECT 45] Entered gun state: feeding")

  -- vfx, delays and updates chamber status
  -- if self.manualFeed then animator.playSound("loadRound") end
  self:setAnimationState("gun", "feeding")

  local waitTime = 0
  if self.manualFeed and self.burstCounter >= self.burstCount then
    -- sb.logInfo("[PROJECT 45] Manual-fed and burstCounter >= burstCount; waiting cock time")
    waitTime = self.cockTime/2
  else
    -- sb.logInfo("[PROJECT 45] Not Manual-fed or burstCounter < burstCount; waiting cycle time")
    waitTime = self.cycleTime/3
  end
  util.wait(waitTime)
  
  -- if was just done bursting, push bolt
  if self.manualFeed and self.burstCounter >= self.burstCount then animator.playSound("boltPush") end

  if self.chargeTimer <= 0 then
    self:setAnimationState("gun", "idle")
  else
    self:setAnimationState("gun", "charging")
  end
  storage.chamberReady = true

  if self.burstCounter < self.burstCount then
    self:setState(self.firing)
  end

  -- gives cooldown when either manual feeding a non-slam-fire gun (like a bolt-action rifle)
  -- or if it's a charged/woundup gun and charge progress is reset every shot (think apex legends charge rifle)
  if (self.manualFeed and not self.slamFire) or (self.resetChargeAfterFire and self.chargeTime > 0) then
    self.triggered = true
    self.cooldownTimer = self.fireTime
  end

end

-- done after magazine is absent
function SynthetikMechanics:reloading()
  self.triggered = true
  self.currentScreenShake = self.screenShakeAmount[1]
  -- if status.overConsumeResource("energy", self.reloadEnergyCostRate*status.resourceMax("energy")) then
  if not status.resourceLocked("energy") then
    
    self.chargeTimer = 0
    self.isCharging = false
    
    self:setAnimationState("mag", "present") -- insert mag
    animator.playSound("insertMag")

    
    -- RELOAD MINIGAME  
    self.weapon:setStance(self.stances.reloading)
    local badScore = 0 -- for bullet counted reload

    self.reloadTimer = 0 -- begin minigame

    local uiUpdateTimer = 0
    local uiUpdateTime = 0.5

    local reloadAttempted = false
    storage.reloadRating = "ok"
    activeItem.setScriptedAnimationParameter("reloadRating", "")

    while self.reloadTimer < self.reloadTime
    and storage.ammo < self.maxAmmo
    and not status.resourceLocked("energy") do

      -- increment timer
      self.reloadTimer = self.reloadTimer + self.dt

      -- update UI
      if uiUpdateTimer >= uiUpdateTime then
        storage.reloadRating = "ok"
      else
        uiUpdateTimer = uiUpdateTimer + self.dt
      end

      -- if triggered,
      if self:triggering() and not self.triggered and not reloadAttempted then
        self.triggered = true
        reloadAttempted = true
        uiUpdateTimer = 0
        -- replenish ammo
        storage.ammo = storage.ammo < 0 and self.bulletsPerReload or storage.ammo + self.bulletsPerReload
        
        -- consume energy for this cycle
        status.overConsumeResource("energy", status.resourceMax("energy") * math.min(self.maxAmmo, self.bulletsPerReload) * self.reloadEnergyCostRate / self.maxAmmo)
      
        -- if within perfect reload then indicate and set reloadRating to good (affects jam chance)
        if self.reloadTime * self.perfectReloadInterval[1] <= self.reloadTimer and self.reloadTimer <= self.reloadTime * self.perfectReloadInterval[2] then
          animator.playSound("goodReload")
          badScore = badScore - self.bulletsPerReload
          storage.reloadRating = "perfect"

        elseif self.reloadTime * self.goodReloadInterval[1] <= self.reloadTimer and self.reloadTimer <= self.reloadTime * self.goodReloadInterval[2] then
          animator.playSound("goodReload")
          storage.reloadRating = "good"
        
        -- otherwise, indicate and set reloadRating to bad (affects jam chance)
        -- also increment badScore for bullet counted reload
        else
          animator.playSound("badReload")
          badScore = badScore + self.bulletsPerReload
          storage.reloadRating = "bad"
        end

        -- if amount reloaded isn't entire ammo capacity, it's bullet-counted
        if storage.ammo < self.maxAmmo then
          -- play sound
          animator.playSound("loadRound")
          -- self:snapStance(self.stances.loadRound)
          -- reset reload attempt for next reload
          reloadAttempted = false
          
          -- reset reload timer to stay in loop
          self.reloadTimer = 0
        end

      end

      -- after handling active reloads,

      -- if ammo is at max capacity, cut off excess bullets and break
      if storage.ammo >= self.maxAmmo then
        storage.ammo  = self.maxAmmo
        break
      end

      coroutine.yield()

    end
    -- end minigame, update ui to indicate reload rating

    -- replenish ammo once if storage.ammo was untouched by reload minigame
    if storage.ammo <= 0 then
      status.overConsumeResource("energy", status.resourceMax("energy") * math.min(self.maxAmmo, self.bulletsPerReload) * self.reloadEnergyCostRate / self.maxAmmo)
      storage.ammo = math.min(self.maxAmmo, self.bulletsPerReload)
    end

    -- if reload was bullet-counted
    if self.bulletsPerReload < self.maxAmmo then

      -- if more than half of bullets were badly loaded, reload rating is bad
      if badScore > storage.ammo / 2 then storage.reloadRating = "bad"

      -- if all bullets were reloaded good or perfectly, reload rating is either good or perfect
      elseif storage.ammo > self.bulletsPerReload then
        if badScore == 0 then storage.reloadRating = "good"
        elseif badScore < 0 then storage.reloadRating = "perfect" end

      -- if at least one bullet is badly loaded, but less than half of the ammo capacity, reload rating is ok
      else storage.reloadRating = "ok" end
    
    end
      
    activeItem.setScriptedAnimationParameter("reloadRating", storage.reloadRating)
    
    self.weapon:setStance(self.stances.reloaded)
    self.burstCounter = self.burstCount
    self:screenShake(self.currentScreenShake)

    if self.magType == "strip" then
      animator.setAnimationState("mag", "absent")
      animator.burstParticleEmitter("magazine")
    end

    -- cock gun
    self:setState(self.cocking)

    sb.logInfo("[PROJECT 45] Empirical Crit Chance: " .. storage.critStats.crits * 100 / storage.critStats.shots .. "%%")

    self:setStance(self.stances.aim)
  else
    animator.playSound("click")

  end

end

-- State specific to charged/windup weapons that are out of ammo
-- Will make them whirr as the trigger key is held
-- Imagine a gatling gun spinning, that'd be nice
function SynthetikMechanics:whirring()
  -- If gun is a gatling gun:
  --[[
    1. Gun is auto
    2. Gun autofires after charge
  --]]
  if self.chargeTimer > 0
  and not self.semi
  and self.autoFireAfterCharge 
  and not self.resetChargeAfterFire then
    while self:triggering() do
      self.chargeTimer = math.min(self.chargeTime, self.chargeTimer + self.dt)
      coroutine.yield()
    end
  end
end

function SynthetikMechanics:cocking()
  if animator.animationState("gun") ~= "ejecting" then
    animator.playSound("boltPull")
    self:setAnimationState("gun", "ejecting")
    util.wait(self.cockTime/3)
  end

  -- if single shot, play sound of single round being loaded
  if self.maxAmmo == 1 then animator.playSound("loadRound") end
  self:setAnimationState("gun", "feeding")

  util.wait(self.cockTime/3)

  self.reloadTimer = -1 -- get rid of reload ui

  animator.playSound("boltPush")
  self:setAnimationState("gun", "idle")
  util.wait(self.cockTime/3)
  self.burstCounter = self.burstCount
  storage.chamberReady = true
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
  animator.playSound("ejectMag")
  self:setAnimationState("mag", "absent")
  if self.magType == "default" then
    self:snapStance(self.stances.ejectmag)
  end

  self:setStance(self.stances.empty)
  storage.ammo = -1
end

function SynthetikMechanics:fireProjectileNeo(projectileType)
  local params = sb.jsonMerge(self.projectileParameters, {})
  params.power = self:damagePerShot(projectileType)
  for i = 1, self.projectileCount * self:calculateMultishot() do
    local projectileId = world.spawnProjectile(
      projectileType,
      self:firePosition(),
      activeItem.ownerEntityId(),
      self:aimVector(self.inaccuracy),
      false,
      params
    )
  end
end

function SynthetikMechanics:fireHitscan(projectileType)
  for i = 1, self.projectileCount * self:calculateMultishot() do
    --[[
    if world.lineTileCollision(mcontroller.position(), self:firePosition()) then
      goto next_projectile
    end
    --]]

  
    -- scan hit down range
    -- hitreg[2] is where the bullet trail terminates,
    -- hitreg[3] is the array of hit entityIds
    local hitReg = self:hitscan()
    local crit = self:crit()
    local statusDamage = "project45damage"
    storage.critStats.shots = storage.critStats.shots + 1
    if crit > 1 then
      storage.critStats.crits = storage.critStats.crits + 1
      statusDamage = "project45critdamage"
    end
    -- if damageable entity has been detected (hitreg[3] is not nil), damage it

    if #hitReg[3] > 0 then
      for _, hitId in ipairs(hitReg[3]) do
        world.sendEntityMessage(hitId, "applyStatusEffect", statusDamage, self:damagePerShot(projectileType) * crit, entity.id()) -- TODO: duplicate and rename damage status effect
      end
    end

    -- bullet trail info inserted to projectile stack that's being passed to the animation script
    -- each bullet trail in the stack is rendered, and the lifetime is updated in this very script too
    local life = self.projectileParameters.fadeTime or 0.5
    table.insert(self.projectileStack, {
      width = self.projectileParameters.hitscanWidth,
      origin = hitReg[1],
      destination = hitReg[2],
      lifetime = life,
      maxLifetime = life,
      color = self.projectileParameters.hitscanColor
    })

    -- hitscan explosion vfx
    world.spawnProjectile(
      "invisibleprojectile",
      hitReg[2],
      activeItem.ownerEntityId(),
      self:aimVector(3.14),
      false,
      {
        damageType = "NoDamage",
        power = 0,
        timeToLive = 0,
        actionOnReap = {
          {
            action = "config",
            file = "/projectiles/explosions/project45_hitexplosion/project45_hitscanexplosion.config"
          }
        }
      }
    )
    
    

  end
end

-- Utility function that scans for an entity to damage.
function SynthetikMechanics:hitscan(isLaser)

  local scanOrig = self:firePosition()

  local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(isLaser and 0 or self.inaccuracy), self.projectileParameters.range or 100))
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

        if pen > (self.projectileParameters.punchThrough or 0) then break end
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
    
    if config.getParameter("twoHanded", true) then
      activeItem.setTwoHandedGrip(stance.twoHanded or false)
    else
      activeItem.setTwoHandedGrip(false)
    end
    
    self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
    
    self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeWeaponRotation), stance.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeArmRotation), stance.armRotation))

  end
end

function SynthetikMechanics:muzzleFlash()

  self:recoil()
  animator.setSoundPitch("fire", sb.nrand(0.01, 1))
  animator.setSoundVolume("hollow", (1 - storage.ammo/self.maxAmmo) * 0.8)

  animator.playSound("fire" .. (self.suppressed and "silent" or ""))
  animator.playSound("hollow")
  if not self.flashHidden then animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3)) end
  animator.burstParticleEmitter("muzzleFlash")
  animator.setLightActive("muzzleFlash", not self.flashHidden)
  activeItem.setScriptedAnimationParameter("muzzleFlash", not self.flashHidden)
  animator.setAnimationState("flash", "flash")
  self.muzzleFlashTimer = self.muzzleFlashTime
  self.muzzleSmokeTimer = self.muzzleSmokeTime
end

function SynthetikMechanics:recoil()
  self:screenShake(self.currentScreenShake)
  activeItem.setRecoil(true)

  local inaccuracy = math.rad(self.recoilDeg[self.shiftHeld and 2 or 1]) * self.recoilMult
  
  self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + inaccuracy
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + inaccuracy

  self.aimProgress = 0

  if self.recoilMomentum then
    mcontroller.addMomentum(vec2.mul(self:aimVector(), self.recoilMomentum * -1))
  end

end

function SynthetikMechanics:dash()

  if not self.dashParams.enabled then return end
  
  local dashDirection
  if mcontroller.xVelocity() ~= 0 then
    dashDirection = mcontroller.movingDirection()
  else
    dashDirection = mcontroller.facingDirection()
  end
  animator.playSound("dash")
  status.addEphemeralEffect("project45dash", self.dashParams.statusTime)
  util.wait(self.dashParams.dashTime, function(dt)
    mcontroller.setVelocity({self.dashParams.speed*dashDirection, 0})
  end)
  mcontroller.setXVelocity(mcontroller.xVelocity() * self.dashParams.endXVelMult)

  self.dashCooldownTimer = self.dashParams.cooldown

end

function SynthetikMechanics:unjam()
  if not self.triggered then
    self.triggered = true
    self:setAnimationState("gun", "unjam")
    animator.playSound("unjam")
    self:screenShake(self.screenShakeAmount[1])
    self:setStance(self.stances.jammed)
    self:snapStance(self.stances.unjam)
    storage.jamAmount = math.max(0, storage.jamAmount - self.unjamAmount)
    if storage.jamAmount > 0 then
      util.wait(self.unjamTime)
      self:setAnimationState("gun", "jammed")
    else
      storage.reloadRating = "ok"
      animator.burstParticleEmitter("ejectionPort")
      self:screenShake(self.screenShakeAmount[2])
      self:setState(self.cocking)
      self:setStance(self.stances.aim)
    end
  end
end

-- UPDATE FUNCTIONS
--[[
function SynthetikMechanics:updateCamera(shiftHeld)

  if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then
    world.callScriptedEntity(storage.cameraProjectile, "updateSource", mcontroller.position())
    activeItem.setCameraFocusEntity(storage.cameraProjectile)
  end

  if shiftHeld then
    storage.cameraProjectile = storage.cameraProjectile or world.spawnProjectile(
      "project45camera",
      mcontroller.position(),
      activeItem.ownerEntityId(),
      {0, 0},
      true,
      {power = 0}
    )
    if world.entityExists(storage.cameraProjectile) then
      world.callScriptedEntity(storage.cameraProjectile, "updatePos", activeItem.ownerAimPosition(), mcontroller.position(), 100)
      activeItem.setCameraFocusEntity(storage.cameraProjectile)
    end
  else
    if storage.cameraProjectile and world.entityExists(storage.cameraProjectile) then
      world.callScriptedEntity(storage.cameraProjectile, "moveToSource", mcontroller.position())
      activeItem.setCameraFocusEntity(storage.cameraProjectile)
    else
      storage.cameraProjectile = nil
    end
  end
end
--]]

function SynthetikMechanics:updateScriptedAnimationParameters()

  -- display
  activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
  activeItem.setScriptedAnimationParameter("gunHand", activeItem.hand())
  activeItem.setScriptedAnimationParameter("aimPosition", activeItem.ownerAimPosition())
  activeItem.setScriptedAnimationParameter("playerPos", mcontroller.position())
  activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)
  activeItem.setScriptedAnimationParameter("jamAmount", storage.jamAmount)
  activeItem.setScriptedAnimationParameter("muzzlePos", self:firePosition())

  
  activeItem.setScriptedAnimationParameter("muzzleSmokeTimer", self.muzzleSmokeTimer)
  
end

function SynthetikMechanics:updateMagAnimation()

  local tag = self.magAnimRange[2]

  -- validation:
  -- self.magAnimRange must be a subset of non-negative integers
  -- the first index of magAnimRange must be strictly greater than the second index
  if self.magAnimRange[1] >= self.magAnimRange[2] or math.min(self.magAnimRange[1], self.magAnimRange[2]) < 0 or self.magLoopFrames <= 0 then
    tag = "default"
  
  -- if ammo is above range or reloading
  elseif storage.ammo > self.magAnimRange[2] or (self.reloadTimer >= 0 and self.bulletsPerReload >= self.maxAmmo) then
    tag = "loop." .. storage.ammo % self.magLoopFrames -- magazine animation loop
    
  -- if ammo is within animation range then
  -- let tag = storage.ammo
  elseif self.magAnimRange[1] <= storage.ammo and storage.ammo <= self.magAnimRange[2] then
    tag = storage.ammo
  
    -- if ammo is below range (i.e. almost empty)
  else
    -- let tag be low end of anim
    tag = self.magAnimRange[1]

  end

  animator.setGlobalTag("ammo", tag)

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

function SynthetikMechanics:drawLaser()

  if self.laser.enabled
  and not world.lineTileCollision(mcontroller.position(), self:firePosition())
  and (storage.isLaserOn or self.laser.alwaysActive)
  and storage.ammo > 0
  and storage.jamAmount == 0  
  then

    -- laser origin is muzzle
    local scanOrig = self:firePosition()

    -- laser distance is distance between aim position and muzzle
    local range = world.magnitude(scanOrig, activeItem.ownerAimPosition())
    
    -- laser destination is aimvector * distance
    local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(0), self.laser.maxRange and self.laser.range or math.min(self.laser.range, range)))
    
    -- collide laser with terrain
    scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest

    activeItem.setScriptedAnimationParameter("laserOrigin", scanOrig)
    activeItem.setScriptedAnimationParameter("laserDestination", scanDest)

  else
    activeItem.setScriptedAnimationParameter("laserOrigin", nil)
    activeItem.setScriptedAnimationParameter("laserDestination", nil)
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

function SynthetikMechanics:damagePerShot(projectileType)
  --[[
  Damage per shot is calculated by the following factors:
  1. Base Damage as specified in the primaryAbility field of the activeItem
     OR
     Base DPS * (Cycle time + Fire time)
  2. x1.1 damage if the reload rating is good, x1.3 if perfect
  3. Power Multiplier of the player
  4. Tier of the weapon
  5. Critical Roll (calculated when firing hitscan)
  6. Last Shot Damage Multiplier

  The calculated damage is distributed between the projectiles spawned per shot. In eseence, hitting all pellets of
  a shotgun shot deals the complete amount of damage.

  --]]

  local baseDamage = self.baseDamage
  if self.baseDps then
    baseDamage = self.baseDps * (self.manualFeed and self.cockTime or self.cycleTime + self.fireTime)
  end

  local reloadDamageMultiplier = 1

  -- projectile is fired before ammo is decremented
  local lastShotDamageMultiplier = storage.ammo == math.min(self.ammoPerShot, storage.ammo) and self.lastShotDamageMult or 1
  
  if storage.reloadRating == "good" then reloadDamageMultiplier = 1.1 
  elseif storage.reloadRating == "perfect" then reloadDamageMultiplier = 1.3 end
  return baseDamage -- or (self.baseDps * (self.cycleTime + self.fireTime))
   * self.chargeDamageMult
   * reloadDamageMultiplier
   * lastShotDamageMultiplier
   * config.getParameter("damageLevelMultiplier", 1)
   * activeItem.ownerPowerMultiplier()
   / (((projectileType == "project45stdbullet" and not self.overrideHitscan) or projectileType == "hitscan") and 1 or self.projectileCount)
   --]]
end

function SynthetikMechanics:screenShake(amount, shakeTime, random)
  if not self.doScreenShake then return end
  local source = mcontroller.position()
  local shake_dir = vec2.mul(self:aimVector(0), -1 * (amount or 0.1))
  if random then vec2.rotate(shake_dir, 3.14 * truerand()) end
  local cam = world.spawnProjectile(
    "invisibleprojectile",
    vec2.add(source, shake_dir),
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
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(self.weapon.muzzleOffset, self.weapon.relativeWeaponRotation)))
end

function SynthetikMechanics:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand((inaccuracy or 0), 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  aimVector = vec2.rotate(aimVector, (self.weapon.relativeArmRotation + self.weapon.relativeWeaponRotation) * mcontroller.facingDirection())
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
  if self:diceRoll(self.jamChances[storage.reloadRating]) then
    storage.ammo = storage.ammo - math.min(self.ammoPerShot, storage.ammo)
    self.currentScreenShake = self.screenShakeAmount[1]
    self.chargeTimer = 0
    self.isCharging = false
    storage.jamAmount = 1
    animator.playSound("jammed")
    self:setAnimationState("gun", "jammed")
    return true
  end
  return false
end

-- returns whether ammo will be consumed
function SynthetikMechanics:willConsumeAmmo()
  if self:diceRoll(self.ammoConsumeChance, true) then
    return true
  end
  return false
end

-- returns a projectile count multiplier
function SynthetikMechanics:calculateMultishot()
  -- make base multishot integer
  local baseMultishot = math.floor(self.multishot)
  
  -- use decimal as chance for additional shot
  if self:diceRoll(self.multishot - baseMultishot, false) then
    return baseMultishot + 1
  end
  return baseMultishot
end

-- returns a critical multiplier
function SynthetikMechanics:crit()
  if self:diceRoll(self.critChance, true) then
    return self.critDamageMult
  end
  return 1
end

-- Returns true if the diceroll for the given chance is successful
function SynthetikMechanics:diceRoll(chance, inclusive)
  -- clamp chance between 0% and 100%
  local chance = chance < 0 and 0 or chance > 1 and 1 or chance
  local diceRoll = truerand()
  -- sb.logInfo("[PROJECT 45] Dice Rolled: " .. diceRoll)
  return inclusive and diceRoll <= chance or diceRoll < chance -- function like orig function
end

function truerand()
  math.randomseed(math.floor(sb.nrand(5, os.time()))) -- set random seed with sb.nrand, mean = epoch time, stdev = 5
  return math.random()
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
  
  self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + math.rad(stance.weaponRotation)
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + math.rad(stance.armRotation)

  self.aimProgress = 0
end