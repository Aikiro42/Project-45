require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/project45/hitscanLib.lua"
require "/scripts/project45/project45util.lua"

require "/items/active/weapons/ranged/gunfire.lua"
require "/items/active/weapons/ranged/abilities/altfire.lua"

local BAD, OK, GOOD, PERFECT = 1, 2, 3, 4
local reloadRatingList = {"BAD", "OK", "GOOD", "PERFECT"}

Project45GunFire = WeaponAbility:new()

function Project45GunFire:init()

  -- INITIALIZATIONS
  self.debugTimer = self.debugTime
  self.isFiring = false
    
  -- separate cock time and reload time
  -- self.reloadTime = self.reloadTime * 0.8
  self.reloadTimer = -1
  activeItem.setScriptedAnimationParameter("reloadTimer", -1)

  -- initialize charge frame
  self.chargeFrame = 1

  -- initialize charge damage
  self.chargeDamage = 1

  -- initialize burst counter
  storage.burstCounter = storage.burstCounter or self.burstCount
  storage.primaryChargeTime = self.chargeTime + self.overchargeTime
  -- VALIDATIONS

  -- SETTING VALIDATIONS: These validations serve to reduce firing conditions and allow consistent logic.

  -- self.autoFireOnFullCharge only matters if the gun is semifire
  -- if an autofire gun is the kind that's charged, the charge is essentially it winding up.
  self.autoFireOnFullCharge = (self.semi and self.projectileKind ~= "beam") and self.autoFireOnFullCharge

  -- self.fireBeforeOvercharge only matters if the gun is auto
  -- If this setting is false,
  -- then the gun only autofires at max charge, defeating the purpose of
  -- the overcharge providing bonus damage...
  -- Unless the gun continues firing until the gun is undercharged. (Should this be implemented?)
  self.fireBeforeOvercharge = not self.semi

  -- self.resetChargeOnFire only matters if gun doesn't fire before overcharge
  -- otherwise, the gun will never overcharge
  -- If this is false and the gun is semifire, then the charge is maintained (while left click is held) and
  -- the gun can be quickly fired again after self.triggered is false
  self.resetChargeOnFire = not self.fireBeforeOvercharge and self.resetChargeOnFire

  -- self.manualFeed only matters if the gun is semifire.
  -- Can you imagine an automatic bolt-action gun?
  self.manualFeed = self.semi and self.manualFeed

  -- self.slamFire only matters if the gun is manual-fed (bolt-action)
  self.slamFire = self.manualFeed and self.slamFire

  -- Let recoilMult affect recoilMaxDeg
  self.recoilMaxDeg = self.recoilMaxDeg * self.recoilMult

  -- only load rounds through bolt if gun has internal mag
  self.loadRoundsThroughBolt = self.internalMag and self.loadRoundsThroughBolt

  self.bulletsPerReload = math.max(1, self.bulletsPerReload)
  self.muzzleSmokeTime = self.muzzleSmokeTime or 1.5

  -- always enable laser if debug is on
  self.laser.enabled = self.debug or self.laser.enabled

  self.projectileFireSettings = self.projectileFireSettings or {}
  self.projectileFireSettings.batchFire = type(self.projectileType) == "table" and self.projectileFireSettings.batchFire

  -- let inaccuracy be a table
  if type(self.inaccuracy) ~= "table" then
    self.inaccuracy = {
      mobile = self.inaccuracy*2,  -- double inaccuracy while running
      walking = self.inaccuracy,  -- standard inaccuracy while walking
      stationary = self.inaccuracy/2, -- halved inaccuracy while standing
      crouching = self.inaccuracy/4 -- quartered inaccuracy while crouching
    }
  end
  self.currentInaccuracy = self.inaccuracy.mobile
  activeItem.setCursor("/cursors/project45-neo-cursor-mobile.cursor")

  -- make recoverTime a table
  if type(self.recoverTime) ~= "table" then
    self.recoverTime = {
      mobile = self.recoverTime*4,  -- quadruple recover time while running
      walking = self.recoverTime*2,  -- double recover time while walking
      stationary = self.recoverTime, -- standard recover time while standing
      crouching = self.recoverTime/2 -- halfed recover time while crouching
    }
  end
  self.currentRecoverTime = self.recoverTime.mobile

  -- initialize self.cycleTimer if cycleTimer is
  -- set to be dynamic
  if type(self.cycleTime) == "table" then
    self.cycleTimeDiff = self.cycleTime[2] - self.cycleTime[1]
    self.cycleTimer = 0
    self.currentCycleTime = self.cycleTime[1]
  else
    self.currentCycleTime = self.cycleTime
  end
  
  -- initialize self.screenShakeTimer if cycleTimer is
  -- set to be dynamic
  if type(self.screenShakeAmount) == "table" then
    self.screenShakeDiff = self.screenShakeAmount[2] - self.screenShakeAmount[1]
    self.screenShakeTimer = 0
    self.currentScreenShake = self.screenShakeAmount[1]
  else
    self.currentScreenShake = self.screenShakeAmount
  end

  -- burst count must be positive
  self.burstCount = math.max(1, self.burstCount)

  -- validate quick reload timeframe;
  -- perfect reload must be within bounds of good reload
  -- and quick reload time frame array must be an increasing sequence
  if self.quickReloadTimeframe[4] < self.quickReloadTimeframe[1] then
    self.quickReloadTimeframe[4], self.quickReloadTimeframe[1] = self.quickReloadTimeframe[1], self.quickReloadTimeframe[4]
  end
  self.quickReloadTimeframe[2] = math.max(self.quickReloadTimeframe[1], self.quickReloadTimeframe[2])
  self.quickReloadTimeframe[3] = math.min(self.quickReloadTimeframe[3], self.quickReloadTimeframe[4])

  -- grab stored data
  self:loadGunState()
  storage.stanceProgress = storage.stanceProgress or 0 -- stance progres is stored in storage so that other abilities may recoil the gun
  self.reloadRatingDamage = self.reloadRatingDamageMults[storage.reloadRating]

  -- initialize timers
  self.chargeTimer = 0
  self.dischargeDelayTimer = 0
  self.cooldownTimer = self.fireTime
  self.muzzleFlashTimer = 0
  storage.altMuzzleFlashTimer = 0
  self.muzzleSmokeTimer = 0

  -- initialize animation stuff

  -- animator.setSoundVolume("ejectCasing", 0.8)
  
  activeItem.setScriptedAnimationParameter("performanceMode", self.performanceMode)

  activeItem.setScriptedAnimationParameter("reloadTimer", -1)
  activeItem.setScriptedAnimationParameter("chargeTimer", 0)
  activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
  
  activeItem.setScriptedAnimationParameter("reloadTime", self.reloadTime)
  activeItem.setScriptedAnimationParameter("quickReloadTimeframe", self.quickReloadTimeframe)

  activeItem.setScriptedAnimationParameter("chargeTime", self.chargeTime)
  activeItem.setScriptedAnimationParameter("overchargeTime", self.overchargeTime)

  
  -- Add functions used by this primaryAbility to altAbility
  GunFire.recoil = self.recoil
  GunFire.rollMultishot = self.rollMultishot -- not working??
  GunFire.updateMagVisuals = self.updateMagVisuals
  GunFire.updateAmmo = self.updateAmmo
  -- Override functions used by altAbility
  GunFire.firePosition = self.firePosition
  GunFire.aimVector = self.aimVector
  GunFire.fireProjectile = self.fireProjectile
  GunFire.cooldown = self.cooldown
  GunFire.auto = self.auto
  GunFire.burst = self.burst
  GunFire.energyPerShot = function() return self.ammoPerShot or 0 end
  GunFire.screenShake = self.screenShake

  -- Add functions used by this primaryAbility to altAbility
  
  AltFireAttack.recoil = self.recoil
  AltFireAttack.rollMultishot = self.rollMultishot
  AltFireAttack.updateMagVisuals = self.updateMagVisuals
  AltFireAttack.updateAmmo = self.updateAmmo
  -- Override functions used by altAbility
  AltFireAttack.firePosition = self.firePosition
  AltFireAttack.aimVector = self.aimVector
  AltFireAttack.fireProjectile = self.fireProjectile
  AltFireAttack.cooldown = self.cooldown
  AltFireAttack.auto = self.auto
  AltFireAttack.burst = self.burst
  AltFireAttack.muzzleFlash = self.altMuzzleFlash
  AltFireAttack.energyPerShot = function() return self.ammoPerShot or 0 end
  AltFireAttack.screenShake = self.screenShake
  --]]

  self:evalProjectileKind()
  self:updateMagVisuals()
  self:updateChamberState()

  -- Final touches before use
  local defaultAimStance = {
    weaponRotation = 0,
    armRotation = 0,
    twoHanded = config.getParameter("twoHanded", false),
    allowRotate = true,
    allowFlip = true
  }
  self.stances = self.stances or {}
  local finalAimStance = self.stances.aimStance or {}
  self.stances.aimStance = util.mergeTable(defaultAimStance, finalAimStance)

  -- compatibility stances
  self.stances.idle = self.stances.aimStance
  self.stances.charge = self.stances.aimStance
  self.stances.fire = self.stances.aimStance
  self.stances.cooldown = self.stances.aimStance

  self.recoverDelayTimer = 0

  if storage.jamAmount <= 0
  and storage.ammo >= 0
  then
    -- self.weapon:setStance(self.stances.aimStance)
    self:setStance(self.stances.aimStance)
  else
    if storage.jamAmount > 0 then
      self:setState(self.jammed)
    end
    if storage.ammo < 0 then
      self:setStance(self.stances.empty)
    end
  end
  self:recoil(true, 1, 45, 0) -- you're bringing the gun up

  self.debugModPositions = {}
  self.debugModPositions.base = config.getParameter("baseOffset", {0, 0})
  self.debugModPositions.rail = config.getParameter("railOffset", {0, 0})
  self.debugModPositions.sights = config.getParameter("sightsOffset", {0, 0})
  self.debugModPositions.underbarrel = config.getParameter("underbarrelOffset", {0, 0})
  self.debugModPositions.stock = config.getParameter("stockOffset", {0, 0})

end

function Project45GunFire:renderModPositionDebug()
  if not self.debug then return end
  
  local weaponPos = vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(self.weapon.weaponOffset, self.weapon.relativeWeaponRotation)))

  local debugPointColors = config.getParameter("debugPointColors", {})

  local modPositions = {
    rail=debugPointColors.rail or "gray",
    sights=debugPointColors.sights or "gray",
    underbarrel=debugPointColors.underbarrel or "gray",
    stock=debugPointColors.stock or "gray",
  }

  for posName, color in pairs(modPositions) do
    world.debugPoint(
      vec2.add(
        mcontroller.position(),
        activeItem.handPosition(
          vec2.rotate(
            vec2.add(self.weapon.weaponOffset, self.debugModPositions[posName]),
            self.weapon.relativeWeaponRotation
          )
        )
      ),
      color
    )
  end

end

function Project45GunFire:update(dt, fireMode, shiftHeld)

  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  -- update timers
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)


  -- world.debugPoint(self:firePosition(true), "cyan")

  -- update relevant stuff
  self:renderModPositionDebug()
  self:updateDebugTimer()
  self:updateLaser()
  self:updateCharge()
  self:updateStance()
  self:updateCycleTime()
  self:updateScreenShake()
  self:updateProjectileStack()
  self:updateMovementControlModifiers()
  self:updateMuzzleFlash()

  if self.debugTimer <= 0 then
    self:debugFunction()
    self.debugTimer = self.debugTime
  end

  -- Prevent energy regen if there is energy or if currently reloading
  if storage.ammo > 0
  or self.reloadTimer > 0
  or not status.resourceLocked("energy") then
    status.setResource("energyRegenBlock", 1)
  end

  if not self.isFiring then
    if not self:triggering() then
      self.triggered = false
    end
    self:stopFireLoop()
  end
  
  -- accuracy settings
  local movementState = self:getMovementState()
  self.currentInaccuracy = self.inaccuracy[movementState]
  self.currentRecoverTime = self.recoverTime[movementState]
  activeItem.setCursor("/cursors/project45-neo-cursor-" .. movementState .. ".cursor")

  -- trigger i/o logic
  if self:triggering()
  and not self.weapon.currentAbility
  and self.cooldownTimer == 0
  and not self.isFiring
  then
    if storage.jamAmount <= 0 then

      if storage.ammo > 0 then

          if animator.animationState("chamber") == "ready"
          and not self.triggered then

            if not self:muzzleObstructed() then
            
              if self.chargeTime + self.overchargeTime > 0 then
                self:setState(self.charging)
              else
                self:setState(self.firing)
              end

            end

          elseif not self.triggered then
            self:setState(self.cocking)

          end
      elseif storage.ammo == 0 and not self.triggered then
        if self.loadRoundsThroughBolt then
          self:setState(self.ejecting)
        else
          self:ejectMag()
        end

      else
        if not self.triggered then
          self:setState(self.reloading)
        end

      end

    else
      self:setState(self.unjamming)

    end

      
    self.cooldownTimer = self.fireTime

  end


end

function Project45GunFire:uninit()
  self:saveGunState()
  activeItem.setScriptedAnimationParameter("beamLine", nil)
  activeItem.setScriptedAnimationParameter("projectileStack", nil)
end

-- SECTION: STATE FUNCTIONS

function Project45GunFire:charging()
  while self:triggering() do

    if (self.fireBeforeOvercharge and self.chargeTimer >= self.chargeTime)
    or (self.autoFireOnFullCharge and self.chargeTimer >= self.chargeTime + self.overchargeTime)
    then
      break
    end

    coroutine.yield()
  end

  if self.chargeTimer >= self.chargeTime then
    self:setState(self.firing)
  end

end

function Project45GunFire:jammed()
  self:setStance(self.stances.jammed)
end

function Project45GunFire:firing()
  
  self.triggered = self.semi or storage.ammo == 0

  if self:jam() then return end
  -- don't fire when muzzle collides with terrain
  -- if not self.projectileParameters.hitscanIgnoresTerrain and world.lineTileCollision(mcontroller.position(), self:firePosition()) then
  if self:muzzleObstructed() then
    self:stopFireLoop()
    self.isFiring = false
    if self.loopFiringAnimation then
      animator.setAnimationState("gun", "firing")
    end
    self:postFiringTransitionHandler()
    return
  end
  

  self.isFiring = true
  animator.setAnimationState("gun", self.loopFiringAnimation and "firingLoop" or "firing")

  if self.stances.firing then
    self:setStance(self.stances.firing)
  end

  -- reset burst count if already max
  storage.burstCounter = (storage.burstCounter >= self.burstCount) and 0 or storage.burstCounter

  self:startFireLoop()

  self:fireProjectile()

  if self.projectileFireSettings.batchFire then
    self:rerollProjectileIndex()
  end

  self:muzzleFlash()
  self:screenShake()
  self:recoil()

  if self.projectileKind ~= "summoned"
  and self.recoilMomentum > 0
  and not mcontroller.crouching() then
    mcontroller.addMomentum(vec2.mul(self:aimVector(), self.recoilMomentum * -1))
  end

  storage.burstCounter = storage.burstCounter + 1

  if self.resetChargeOnFire then self.chargeTimer = 0 end

  -- add unejected casings

  storage.unejectedCasings = storage.unejectedCasings + math.min(self.ammoPerShot, storage.ammo)
  self:updateAmmo(project45util.diceroll(self.ammoConsumeChance) and -self.ammoPerShot or 0)
  
  self.triggered = storage.ammo == 0 or self.triggered
  
  self:updateChamberState("filled")
  
  -- if gun fires a loop
  if self.loopFiringAnimation
  and self:triggering() and storage.ammo > 0 then
    util.wait(self.currentCycleTime)
    self:setState(self.firing)
    return
  end

  self:postFiringTransitionHandler()

end

function Project45GunFire:postFiringTransitionHandler()

  -- if not a manual feed gun
  -- or if the gun's not done bursting
  -- then eject immediately
    if not self.manualFeed
    or storage.burstCounter < self.burstCount
    then
      if self.ejectCasingsAfterBurst
      and storage.burstCounter < self.burstCount
      and storage.ammo > 0
      then
        util.wait(self.currentCycleTime)
        self:setState(self.firing)
      else
        util.wait(self.currentCycleTime/3)
        if storage.ammo == 0 and self.ejectMagOnEmpty and self.ejectMagOnEmpty == "firing" then
          self:ejectMag()
        end  
        self:setState(self.ejecting)
      end
    -- otherwise, stop the cycle process
    else
      if storage.ammo == 0 and self.ejectMagOnEmpty and self.ejectMagOnEmpty == "firing" then
        self:ejectMag()
      end
      self:stopFireLoop()
      self.cooldownTimer = self.fireTime
      self.isFiring = false
    end
end

function Project45GunFire:ejecting()

  
  if not self.ejectCasingsWithMag
  and self.ejectBeforeAnimation
  then
    self:discardCasings()
    self:updateChamberState("empty") -- empty chamber
  end

  -- if gun is cocked per shot
  -- and it's done bursting
  -- pull the bolt (slower animation)
  if (self.manualFeed
  and storage.burstCounter >= self.burstCount
  or self.reloadTimer >= 0)
  or self.isCocking
  then
    animator.setAnimationState("gun", "boltPulling")
    animator.playSound("boltPull")
    self:setStance(self.stances.boltPull)
  -- otherwise, the gun is either semiauto
  -- or not done bursting; we eject (faster animation)
  else
    animator.setAnimationState("gun", "ejecting")
    if self.audibleEjection then animator.playSound("boltPull") end
  end


  -- bolt is open(ing)
  animator.setAnimationState("bolt", "open")

  -- if the gun is cocked per shot
  -- and the gun is done bursting,
  -- we for the cock animation to end
  -- otherwise, the gun is semiauto or the gun isn't done bursting:
  -- we wait for the (half) cycle animation to end
  if (self.manualFeed and (storage.burstCounter >= self.burstCount))
  or (self.reloadTimer >= 0)
  or self.isCocking
  then
    util.wait(self.cockTime/2)
    self.stanceLocked = false
  else
    util.wait(self.currentCycleTime/3)
  end

  if not self.ejectCasingsWithMag
  and not self.ejectBeforeAnimation
  then
    self:discardCasings()
  end

  self:updateChamberState("empty") -- empty chamber

  -- if gun has ammo, feed
  if storage.ammo > 0 then
    self:setState(self.feeding)
  
  -- otherwise, reset burst counter (set it to burstcount)
  -- and eject mag if it's supposed to be ejected (like the garand)
  else
    storage.burstCounter = self.burstCount
    if self.ejectMagOnEmpty and self.ejectMagOnEmpty == "ejecting"
    or self.loadRoundsThroughBolt
    then
      self:ejectMag()
    else
      self:setStance(self.stances.aimStance)
    end
    self.isCocking = false
    self.isFiring = false
  end
end

function Project45GunFire:feeding()
  if (self.manualFeed                              -- if gun is cocked every shot
  and storage.burstCounter >= self.burstCount        -- and the gun is done bursting
  or self.reloadTimer >= 0)                         -- or the gun was just reloaded/is cocking
  or self.isCocking
  then

    if self.midCockDelay then
      util.wait(self.midCockDelay)
    end

    animator.playSound("boltPush")                -- then we were cocking back, and we should cock forward
    animator.setAnimationState("gun", "boltPushing")
  else
    animator.setAnimationState("gun", "feeding")
  end

  if self.slamFire
  and self.manualFeed
  and storage.ammo > 0
  and self.reloadTimer < 0
  and storage.burstCounter >= self.burstCount
  and self:triggering() then
    -- do this when slamfiring
    animator.setAnimationState("bolt", "closed")
    self:updateChamberState("ready")
    self.isCocking = false
    self:setStance(self.stances.slamFire or self.stances.boltPush)
    util.wait(self.dt)
    -- self:setStance(self.stances.boltPush, true, true)
    if self.chargeTime + self.overchargeTime > 0 then
      self:setState(self.charging)
    else
      self:setState(self.firing)
    end
    return
  elseif self.manualFeed or self.isCocking then
    self:setStance(self.stances.boltPush)
  end

  -- otherwise, we wait
  if (self.manualFeed and (storage.burstCounter >= self.burstCount))
  or (self.reloadTimer >= 0)
  or self.isCocking
  then
    util.wait(self.cockTime/2)
  else
    util.wait(self.currentCycleTime/3)
  end

  self:setStance(self.stances.aimStance)
  
  animator.setAnimationState("bolt", "closed")
  if storage.ammo > 0 then
    self:updateChamberState("ready")
  end

  self.isCocking = false

  -- if we aren't done bursting,
  -- we continue firing
  if (
    self.chargeTimer >= self.chargeTime
    and self.projectileKind ~= "beam"
    and storage.burstCounter < self.burstCount
  )
  and self.reloadTimer < 0
  then
    self:setState(self.firing)
  end

  -- prevent triggering
  self.triggered = self.semi or self.reloadTimer >= 0
  
  self.reloadTimer = -1  -- mark end of reload
  activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)
  self.isFiring = false
end

function Project45GunFire:reloading()

  -- abort reload and click if energy is locked i.e. regenerating
  if status.resourceLocked("energy") then
    animator.playSound("click")
    self.triggered = true
    return
  end
  
  self.reloadTimer = 0 -- mark begin of reload
  animator.playSound("reloadStart") -- sound of mag being grabbed
  if self.breakAction and animator.animationState("gun") ~= "open" then
    animator.setAnimationState("gun", "open")
  end

  self.triggered = true  -- prevent accidentally reloading instantly
  
  -- general reload rating calculation vars
  local sumRating = 0
  local reloads = 0
  local energyDepletedFlag = false -- prevents additional reload when energy ran out while reloading

  -- visual stuff
  -- dictates appearance of reload ui
  -- and presence of mag (conditionally)
  local displayResetTimer = 0
  local displayResetTime = self.reloadTime / 2
  activeItem.setScriptedAnimationParameter("reloadRating", "")
  if storage.ammo < 0 then storage.ammo = 0 end
  
  if not self.reloadOnEjectMag then
    self:setStance(self.stances.reloading, true)
  end

  -- begin minigame
  -- self.weapon:setStance(self.stances.reloading)
  animator.playSound("reloadLoop", -1)
  while self.reloadTimer <= self.reloadTime do
    activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)

    if displayResetTimer <= 0 and storage.ammo < self.maxAmmo then
      activeItem.setScriptedAnimationParameter("reloadRating", "")
      if self.internalMag then
        animator.setAnimationState("magazine", "present") -- insert mag, hiding it from view
      end
      self:setStance(self.stances.reloading, true)
      displayResetTimer = displayResetTime
    else
      displayResetTimer = math.max(0, displayResetTimer - self.dt)
    end
    
    -- process left click
    -- do not process left click if (full) bad reload has been attempted
    if self:triggering() and not self.triggered and storage.ammo < self.maxAmmo then
      
      -- audiovisual stuff; play load round if the mag isn't loaded in one go
      if self.bulletsPerReload < self.maxAmmo then animator.playSound("loadRound") end
      if self.internalMag then
        animator.setAnimationState("magazine", "absent")
      end
      if self.ejectMagOnReload then
        animator.burstParticleEmitter("magazine") -- throw mag strip
      end

      -- count reload
      reloads = reloads + 1
      
      -- get this reload's reloadRating
      local reloadRating = self:reloadRating()
      activeItem.setScriptedAnimationParameter("reloadRating", reloadRatingList[reloadRating])
      
      -- add rating to sum
      -- BAD: 0
      -- GOOD: 1
      -- PERFECT: 2
      if reloadRating == BAD then
        animator.playSound("badReload")
      elseif reloadRating == GOOD then
        animator.playSound("goodReload")
        sumRating = sumRating + 1
      elseif reloadRating == PERFECT then
        animator.playSound(self.bulletsPerReload >= self.maxAmmo and "perfectReload" or "goodReload")
        sumRating = sumRating + 2
      end

      self.triggered = true
      
      -- update ammo
      self:setStance(self.stances.loadRound, true)  -- player visually loads round
      local reloadedBullets = storage.ammo -- prevents energy overconsumption when reloaded bullets is greater than max ammo
      self:updateAmmo(self.bulletsPerReload)
      reloadedBullets = storage.ammo - reloadedBullets

      -- proportionally consume energy; break out of loop once out of energy
      status.overConsumeResource("energy", self.reloadCost * (reloadedBullets / self.maxAmmo))
      if not status.resourcePositive("energy") then
        energyDepletedFlag = true
        break
      end

      -- if mag isn't fully loaded, reset minigame
      if storage.ammo < self.maxAmmo then
        self.reloadTimer = 0      
      -- if reload rating is not bad, prematurely end minigame
      -- otherwise, player has to wait until end of reload time
      elseif reloadRating ~= "BAD" then break end

    end   
    self.reloadTimer = self.reloadTimer + self.dt
    coroutine.yield()
  end
  animator.stopAllSounds("reloadLoop")

  self:setStance(self.stances.reloaded, not self.reloadOnEjectMag)
  if self.projectileFireSettings.resetProjectileIndexOnReload then
    storage.savedProjectileIndex = 1
  end
  animator.setAnimationState("magazine", self.internalMag and "absent" or "present")
  
  if self.breakAction then
    animator.setAnimationState("gun", "ejected")

  end

  -- if there hasn't been any input, just load round
  if storage.ammo < self.maxAmmo and not energyDepletedFlag then
    sumRating = sumRating + 0.5 -- OK: 0.5
    reloads = reloads + 1 -- we did a reload
    animator.playSound("loadRound")
    if self.ejectMagOnReload then
      animator.burstParticleEmitter("magazine") -- throw mag strip
    end
    local reloadedBullets = storage.ammo -- prevents energy overconsumption when reloaded bullets is greater than max ammo
    self:updateAmmo(self.bulletsPerReload)
    reloadedBullets = storage.ammo - reloadedBullets

    -- proportionally consume energy; break out of loop once out of energy
    status.overConsumeResource("energy", self.reloadCost * (reloadedBullets / self.maxAmmo))
end
  
  -- begin final reload evaluation
  --                     MAX AVERAGE
  -- |  BAD  |  OK  |  GOOD  ||  PERFECT  >
  local finalReloadRating
  local finalScore = sumRating / reloads
  if finalScore > 1 then
    finalReloadRating = PERFECT
  elseif finalScore > 2/3 then
    finalReloadRating = GOOD
  elseif finalScore > 1/3 then
    finalReloadRating = OK
  else
    finalReloadRating = BAD
  end
  if self.bulletsPerReload < self.maxAmmo and finalReloadRating == PERFECT then
    animator.playSound("perfectReload")
  end
  storage.reloadRating = finalReloadRating
  activeItem.setScriptedAnimationParameter("reloadRating", reloadRatingList[finalReloadRating])
  self.reloadRatingDamage = self.reloadRatingDamageMults[storage.reloadRating]
  animator.playSound("reloadEnd")  -- sound of magazine inserted

  if self.postReloadDelay then
    util.wait(self.postReloadDelay)
  else
    util.wait(self.cockTime/8)
  end

  self:setState(self.cocking)
  
end

function Project45GunFire:cocking()

  self.cooldownTimer = self.fireTime
  self.isCocking = true

  if animator.animationState("bolt") == "closed"
  or self.forceBoltPullWhenCocking
  then
    self:setState(self.ejecting)
    return
  else
    util.wait(self.cockTime/2)
  end

  if animator.animationState("bolt") == "jammed" then
    animator.setAnimationState("gun", "ejected")
    animator.setAnimationState("bolt", "open")
    util.wait(self.cockTime/2)
  end

  if animator.animationState("bolt") == "open" then
    storage.burstCounter = self.burstCount
    self.triggered = true
    self:setState(self.feeding)
    -- self:beginAim()
    return
  end

end

function Project45GunFire:unjamming()
  if self.triggered then return end
  self.triggered = true
  self:screenShake()
  self:recoil(true, 0.5)
  animator.setAnimationState("gun", "unjamming") -- should transist back to being jammed
  animator.playSound("unjam")
  self:setStance(self.stances.unjam, true)
  util.wait(self.cockTime/4)
  self:setStance(self.stances.jammed)

  self:updateJamAmount(math.random() * -1)
  if storage.jamAmount <= 0 then
    -- animator.playSound("click")
    storage.reloadRating = OK
    activeItem.setScriptedAnimationParameter("reloadRating", reloadRatingList[OK])
    self.reloadTimer = self.reloadTime
    animator.setAnimationState("bolt", "closed")
    animator.setAnimationState("chamber", "filled")
    self:setState(self.cocking)
    return
  end
end

-- SECTION: ACTION FUNCTIONS

-- Returns true if the weapon successfully jammed.
function Project45GunFire:jam()
  if project45util.diceroll(self.jamChances[storage.reloadRating]) then

    self:stopFireLoop()
    animator.playSound("jam")
    
    animator.setAnimationState("bolt", "jammed")
    animator.setAnimationState("gun", "jammed")
    self:updateChamberState("filled")
    storage.unejectedCasings = math.min(storage.ammo, storage.unejectedCasings + self.ammoPerShot)
    self:updateAmmo(-self.ammoPerShot)
    
    -- prevent triggering and firing
    self.triggered = true
    self.isFiring = false
    if self.screenShakeTimer then self.screenShakeTimer = 0 end
    storage.burstCounter = self.burstCount
    self.chargeTimer = self.resetChargeOnJam and 0 or self.chargeTimer
    
    self:updateJamAmount(1, true)
    self:setState(self.jammed)
    return true
  end
  return false
end

function Project45GunFire:muzzleFlash()

  -- fire muzzle projectile
  if not self.muzzleProjectileFired then
    if self.muzzleProjectileType then
      if self.projectileKind ~= "projectile" then
        self:fireMuzzleProjectile(
          self.muzzleProjectileType,
          self.muzzleProjectileParameters,
          nil,
          self.muzzlePosition and self:muzzlePosition(nil, self.muzzleProjectileOffset),
          nil,
          self.muzzleVector and self:muzzleVector(0, nil, self.muzzlePosition and self:muzzlePosition()),
          self.muzzleProjectileOffset
        )
      else
        self:fireProjectile(
          self.muzzleProjectileType,
          self.muzzleProjectileParameters,
          nil,
          self.muzzlePosition and self:muzzlePosition(),
          nil,
          self.muzzleVector and self:muzzleVector(0, nil, self.muzzlePosition and self:muzzlePosition())
        )
      end
    end
    if self.muzzleProjectileFired == false then 
      self.muzzleProjectileFired = true
    end
  end

  if (self.projectileKind or "projectile") ~= "beam" then
    -- play fire and hollow sound if the gun isn't firing a beam
    animator.setSoundPitch("fire", sb.nrand(0.01, 1))
    animator.setSoundVolume("hollow", util.clamp((1 - storage.ammo/self.maxAmmo) * self.hollowSoundMult, 0, self.hollowSoundMult))
    animator.playSound("fire")
    animator.playSound("hollow")
  end
  
  if not self.performanceMode then animator.burstParticleEmitter("muzzleFlash") end
  
  if not self.hideMuzzleFlash then
    animator.setLightActive("muzzleFlash", true)
    animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
    if not config.getParameter("overrideMuzzleFlashDirectives") then
      animator.setPartTag("muzzleFlash", "directives", string.format("?fade=%02X%02X%02X",self.muzzleFlashColor[1], self.muzzleFlashColor[2], self.muzzleFlashColor[3]) .. "=1")
    end
    animator.setAnimationState("flash", "flash")
    self.muzzleFlashTimer = self.muzzleFlashTime or 0.05
  end

  if self.hideMuzzleSmoke ~= nil and not self.hideMuzzleSmoke then
    self.muzzleSmokeTimer = self.muzzleSmokeTime + self.currentCycleTime + 0.1
  end
end

function Project45GunFire:startFireLoop()
  if not self.fireLoopPlaying then
    animator.playSound("fireStart")
    animator.playSound("fireLoop", -1)
    self.fireLoopPlaying = true
  end
end

function Project45GunFire:stopFireLoop()
  -- FIXME: Fire loop doesn't stop when autoFireOnFullCharge is true and gun is held down
  -- A temporary fix is to change the sounds of the gun...
  if self.fireLoopPlaying then
    animator.stopAllSounds("fireLoop")
    animator.playSound("fireEnd")
    self.fireLoopPlaying = false
  end
end

function Project45GunFire:fireProjectile(projectileType, projectileParameters, inaccuracy, firePosition, projectileCount, aimVector, addOffset)
  local params = sb.jsonMerge(self.projectileKind == "summoned" and self.summonedProjectileParameters or self.projectileParameters, projectileParameters or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileKind == "summoned" and self.summonedProjectileType or self.projectileType
  end
  
  if type(projectileType) == "table" then
    projectileType = projectileType[storage.savedProjectileIndex]
    if not self.projectileFireSettings or not self.projectileFireSettings.batchFire then
      self:rerollProjectileIndex(#projectileType)
    end
  end
  
  local projectileId = 0
    
  for i = 1, (projectileCount or (self.projectileCount * self:rollMultishot())) do

    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
      projectileType,
      firePosition or self:firePosition(nil, addOffset),
      activeItem.ownerEntityId(),
      aimVector or self:aimVector(inaccuracy or self.spread),
      false,
      params
    )

  end

  return projectileId
  
end

-- Ejects casings, purely virtual
function Project45GunFire:discardCasings(numCasings)

  if self.performanceMode then
    storage.unejectedCasings = 0
    return
  end

  if storage.unejectedCasings > 0 or numCasings then
    animator.setParticleEmitterBurstCount("ejectionPort", numCasings or storage.unejectedCasings)
    animator.burstParticleEmitter("ejectionPort")
    for casing = numCasings or storage.unejectedCasings, 0, -1 do
      animator.setSoundPitch("ejectCasing", sb.nrand(0.075, 1))
      animator.playSound("ejectCasing")
    end
    storage.unejectedCasings = 0
  end
end

-- Kicks gun muzzle up and backward, shakes screen
function Project45GunFire:recoil(down, mult, amount, recoverDelay)

  self.projectileKind = self.projectileKind or "projectile"

  local mult = mult or self.recoilMult or 1
  mult = down and -mult or mult
  local crouchMult = mcontroller.crouching() and self.recoilCrouchMult or 1
  mult = mult * crouchMult

  -- recoil (max defaults to 7.5 degrees, amount defaults to 1)
  if self.projectileKind ~= "summoned" then
    local recoilMaxDeg = self.recoilMaxDeg or 7.5
    self.weapon.relativeWeaponRotation = math.min(self.weapon.relativeWeaponRotation, util.toRadians(recoilMaxDeg * crouchMult / 2)) + util.toRadians((amount or self.recoilAmount or 1) * mult/2)
    self.weapon.relativeArmRotation = math.min(self.weapon.relativeArmRotation, util.toRadians(recoilMaxDeg * crouchMult / 2)) + util.toRadians((amount or self.recoilAmount or 1) * mult/2)
  end
  
  self.weapon.weaponOffset = {-0.125, 0}

  -- inaccuracy (defaults to 3 degrees)
  local inaccuracy = util.toRadians(sb.nrand(self.currentInaccuracy or 3, 0) * mult)
  if self.recoilUpOnly and self.projectileKind ~= "summoned" then
    inaccuracy = math.abs(inaccuracy)
  end
  self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + inaccuracy/2
  
  -- recover delay (no recover delay by default)
  storage.stanceProgress = 0
  self.recoverDelayTimer = recoverDelay or self.recoverDelay or self.fireTime or 0
end

-- Ejects mag
-- can immediately begin reloading minigame
function Project45GunFire:ejectMag()

  self.triggered = true
  storage.burstCounter = 0

  if not self.ejectMagOnEmpty or (self.ejectMagOnEmpty ~= "firing" and self.ejectMagOnEmpty ~= "ejecting") then
    self:screenShake(0.5)
    -- self:recoil(true) -- Removed; recoil now dictated via the stance's armRecoil and weaponRecoil
  end
  
  -- audiovisually eject mag if it isn't an internal mag
  if self.breakAction then
    animator.setAnimationState("gun", "open")
  end
  animator.setAnimationState("magazine", "absent")
  if not self.ejectMagOnReload then
    animator.playSound("ejectMag")
    animator.burstParticleEmitter("magazine")
  end
  self:setStance(self.stances.empty)

  if self.ejectCasingsWithMag then
    -- if the mag is internal,
    -- discard any undiscarded casings instead
    self:discardCasings()
  end

  self:updateAmmo(-1, true)
  if self.resetChargeOnEject then
    self.chargeTimer = 0
  end
  
  if self.reloadOnEjectMag then
    self:setState(self.reloading)
  end
end

-- Shakes screen opposite direction of aim.
-- It does this by briefly spawning a projectile that has a short time to live,
-- and setting the cam's focus on that projectile.
function Project45GunFire:screenShake(amount, shakeTime, random)
  
  if self.usedByNPC
  or self.performanceMode
  then return end
  
  local amount = amount or self.currentScreenShake or 0.1
  if amount == 0 then return end

  local source = mcontroller.position()
  local shake_dir = vec2.mul(self:aimVector(0), amount)
  if random then vec2.rotate(shake_dir, 3.14 * math.random()) end
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

-- SECTION:  UPDATE FUNCTIONS

function Project45GunFire:updateDebugTimer()
  self.debugTimer = math.max(0, self.debugTimer - self.dt)
end

-- Updates the charge of the gun
-- This is supposed to be called every tick in `Project45GunFire:update()`
function Project45GunFire:updateCharge()

  -- from here on out, either self.chargeTime or self.overchargeTime is nonzero.
  -- It's safe to divide by their sum.

  if self:triggering()
  and not self.triggered
  and storage.jamAmount <= 0
  and self.reloadTimer < 0
  and (self.maintainChargeOnEmpty or storage.ammo > 0)
  and (self.chargeWhenObstructed or not self:muzzleObstructed())
  and (self.manualFeed and animator.animationState("chamber") == "ready" or not self.manualFeed)
  then
    self.chargeTimer = math.min(self.chargeTime + self.overchargeTime, self.chargeTimer + self.dt)
    self.dischargeDelayTimer = self.dischargeDelayTime
  else
    if self.dischargeDelayTimer <= 0 then
      self.chargeTimer = math.max(0, self.chargeTimer - self.dt * self.dischargeTimeMult)
    else
      self.dischargeDelayTimer = math.max(0, self.dischargeDelayTimer - self.dt)
    end
  end
  activeItem.setScriptedAnimationParameter("chargeTimer", self.chargeTimer)

  if self.chargeTimer <= 0 then
    if animator.animationState("charge") == "charging"
    or animator.animationState("charge") == "chargingProg"
    then
      animator.setAnimationState("charge", "off")
    end
    animator.setParticleEmitterActive("chargeSmoke", false)
    animator.stopAllSounds("chargeDrone")    
    animator.stopAllSounds("chargeWhine")
    self.chargeLoopPlaying = false
    return
  end

  -- update variables dependent on the charge timer:

  -- update charge damage multiplier
  if self.overchargeTime > 0 then
    self.chargeDamage = 1 + ((self.chargeTimer - self.chargeTime) / self.overchargeTime)
  end

  -- update sounds
  local chargeProgress = self.chargeTimer / (self.chargeTime > 0 and self.chargeTime or self.overchargeTime)
  animator.setSoundVolume("chargeDrone", 0.25 + 0.7 * math.min(chargeProgress, 2))
  animator.setSoundPitch("chargeWhine", 1 + 0.3 * math.min(chargeProgress, 2))
  animator.setSoundVolume("chargeWhine", 0.25 + 0.75 * math.min(chargeProgress, 2))

  -- start/stop sounds accordingly
  if self.chargeTimer > 0 and not self.chargeLoopPlaying then
    animator.playSound("chargeDrone", -1)
    animator.playSound("chargeWhine", -1)
    self.chargeLoopPlaying = true
  elseif self.chargeTimer <= 0 and self.chargeLoopPlaying then
    animator.stopAllSounds("chargeDrone")    
    animator.stopAllSounds("chargeWhine")
    self.chargeLoopPlaying = false
  end

  local timeBasis = self.chargeTime
  if self.animateBeforeOvercharge and timeBasis <= 0 then
    timeBasis = self.overchargeTime
  elseif not self.animateBeforeOvercharge then
    timeBasis = timeBasis + self.overchargeTime
  end

  -- charge smoke
  if self.chargeSmoke and not self.performanceMode then
    animator.setParticleEmitterActive("chargeSmoke", true)
    animator.setParticleEmitterEmissionRate("chargeSmoke", math.floor(self.maxChargeSmokeEmissionRate * self.chargeTimer / timeBasis))
  end

  if self.chargeTimer > 0 then
    animator.setAnimationState("charge", self.progressiveCharge and "chargingProg" or "charging")
  else
    animator.setAnimationState("charge", "off")
  end

  -- update current charge frame (1 to n)
  if self.progressiveCharge then
    self.chargeFrame = util.clamp(math.ceil(self.chargeFrames * (self.chargeTimer / timeBasis)), 1, self.chargeFrames)
    animator.setGlobalTag("chargeFrame", self.chargeFrame)
  end

end

-- Updates the gun's ammo:
-- Sets the gun's stored ammo count 
-- and updates the animation parameter.
-- If not setting the value, the ammo is clamped
-- between 0 and max ammo.
function Project45GunFire:updateAmmo(delta, willReplace)

  if not self.maxAmmo then
    storage.ammo = math.max(0, storage.ammo + delta)
    activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
    return
  end
  
  storage.ammo = willReplace and delta or util.clamp(storage.ammo + delta, 0, self.maxAmmo)
  -- update visual info
  self:updateMagVisuals()
  activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
end

function Project45GunFire:updateChamberState(newChamberState)
  if newChamberState then animator.setAnimationState("chamber", newChamberState) end
  activeItem.setScriptedAnimationParameter("primaryChamberState", animator.animationState("chamber"))
end

function Project45GunFire:updateMagVisuals()

  if storage.ammo < 0
  or self.internalMag
  then
    if self.internalMag then animator.setPartTag("magazine", "ammo", "default") end
    animator.setAnimationState("magazine", "absent")
    return
  end

  if not self.magFrames
  or (self.magFrames == 1 and storage.ammo >= 0 or self.performanceMode) then
    animator.setPartTag("magazine", "ammo", "default")
    animator.setAnimationState("magazine", "present")
    return
  end

  local ammoFrame
  if self.magVisualPercentage then
    local ammoPercent = math.ceil(storage.ammo * 100 / self.maxAmmo)
    ammoFrame = "present." .. math.floor(ammoPercent * self.magFrames)
  else
    if storage.ammo > self.magAmmoRange[2] then
      ammoFrame = "loop." .. storage.ammo % self.magLoopFrames
    elseif storage.ammo >= self.magAmmoRange[1] then
      ammoFrame = storage.ammo
    else
      ammoFrame = self.magAmmoRange[1]
    end
  end
  animator.setPartTag("magazine", "ammo", ammoFrame)
end

-- Updates the gun's jam amount.
-- Amount is clamped between 0 and 1.
function Project45GunFire:updateJamAmount(delta, set)
  storage.jamAmount = set and delta or util.clamp(storage.jamAmount + delta, 0, 1)
  activeItem.setScriptedAnimationParameter("jamAmount", storage.jamAmount)
end

function Project45GunFire:updateCycleTime()
  -- don't bother updating cycle time if cycleTimeProgress wasn't even instantiated
  -- or if there's no difference between the cycle times
  -- this means that the cycle time is expected to be constant
  if not self.cycleTimer
  or self.cycleTimeDiff == 0
  then return end

  if self:triggering()
  and not self.triggered
  and self.chargeTimer >= self.chargeTime
  then
    self.cycleTimer = math.min(self.cycleTimer + (self.dt * self.cycleTimeGrowthRate), self.cycleTimeMaxTime)
  else
    self.cycleTimer = math.max(0, self.cycleTimer - (self.dt * self.cycleTimeDecayRate))
  end
  
  local cycleTimeProgress = self.cycleTimer / self.cycleTimeMaxTime
  
  self.currentCycleTime = self.cycleTime[1] + self.cycleTimeDiff * cycleTimeProgress
  -- self.chargeAnimationTime = self.currentCycleTime/3 -- dafuq is this for?
end

function Project45GunFire:updateScreenShake()
  -- don't bother updating cycle time if cycleTimeProgress wasn't even instantiated
  -- this means that the screen shake is expected to be constant
  if not self.screenShakeTimer then
    return end

  if self:triggering()
  --[[
  and not self.triggered
  and storage.jamAmount <= 0
  and self.reloadTimer < 0
  and storage.ammo > 0
  and not self:muzzleObstructed()
  and (self.manualFeed and animator.animationState("chamber") == "ready" or not self.manualFeed)
  and self.chargeTimer > self.chargeTime
  --]]
  then
    self.screenShakeTimer = math.min(self.maxScreenShakeTime, self.screenShakeTimer + self.dt)
  else
    self.screenShakeTimer = math.max(0, self.screenShakeTimer - self.dt)
  end

  local screenShakeProgress = self.screenShakeTimer / self.maxScreenShakeTime
  self.currentScreenShake = self.screenShakeAmount[1] + self.screenShakeDiff * screenShakeProgress
end

function Project45GunFire:updateMovementControlModifiers(shiftHeld)
  -- Modify movement based on whether the player is walking or not
  if shiftHeld then
    mcontroller.controlModifiers({
      speedModifier = self.movementSpeedFactor > 1 and 1 or self.movementSpeedFactor,
      airJumpModifier = self.jumpHeightFactor,
      runningSuppressed = self.heavyWeapon
    })
  else
    mcontroller.controlModifiers({
      speedModifier = self.movementSpeedFactor,
      airJumpModifier = self.jumpHeightFactor,
      runningSuppressed = self.heavyWeapon
    })
  end
end

function Project45GunFire:updateMuzzleFlash()
  self.muzzleFlashTimer = math.max(0, self.muzzleFlashTimer - self.dt)
  storage.altMuzzleFlashTimer = math.max(0, storage.altMuzzleFlashTimer - self.dt)
  
  if animator.animationState("gun") ~= "open" then
    self.muzzleSmokeTimer = math.max(0, self.muzzleSmokeTimer - self.dt)
  else
    self.muzzleSmokeTimer = 0
  end
  if self.muzzleFlashTimer <= 0 then
    animator.setLightActive("muzzleFlash", false)
  end

  if storage.altMuzzleFlashTimer <= 0 then
    animator.setLightActive("altMuzzleFlash", false)
  end

  if not self.hideMuzzleSmoke then
    animator.setParticleEmitterActive("muzzleSmoke", self.muzzleSmokeTimer > 0 and self.muzzleSmokeTimer < self.muzzleSmokeTime and not self.isFiring)
  end
end

-- updates the weapon's stance
-- interpolates the weapon's stance to the stance set via self.weapon:setStance()
function Project45GunFire:updateStance()
  
  if self.weapon.stance == self.stances.reloading
  or self.weapon.stance == self.stances.loadRound
  or self.stanceLocked
  then return end

  if self.recoverDelayTimer > 0 then
    self.recoverDelayTimer = self.recoverDelayTimer - self.dt
    return
  end

  local offset_i = self.weapon.weaponOffset
  local offset_o = self.weapon.stance.weaponOffset or {0, 0}

  self.weapon.weaponOffset = {
    interp.sin(storage.stanceProgress, offset_i[1], offset_o[1]),
    interp.sin(storage.stanceProgress, offset_i[2], offset_o[2])
  }
  -- self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(storage.stanceProgress, math.deg(self.weapon.relativeWeaponRotation), self.weapon.stance.weaponRotation))
  self.weapon.relativeArmRotation = util.toRadians(interp.sin(storage.stanceProgress, math.deg(self.weapon.relativeArmRotation), self.weapon.stance.armRotation))
  
  -- update stance progress
  storage.stanceProgress = math.min(1, storage.stanceProgress + self.dt / self.currentRecoverTime)

end

function Project45GunFire:updateCursor()
  self.currentRecoverTime = 
    (not mcontroller.groundMovement() and self.recoverTime.mobile)     or
        (mcontroller.walking()        and self.recoverTime.walking)    or 
        (mcontroller.crouching()      and self.recoverTime.crouching)  or
    (not mcontroller.running()        and self.recoverTime.stationary) or 
                                          self.recoverTime.mobile
end

-- SECTION: EVAL FUNCTIONS

function Project45GunFire:rerollProjectileIndex(projectileTypeListLength)
  storage.savedProjectileIndex = self.projectileFireSettings and self.projectileFireSettings.sequential and
  (storage.savedProjectileIndex % (projectileTypeListLength or #self.projectileType)) + 1
  or math.random(projectileTypeListLength or #self.projectileType)
end

-- Replaces certain functions and initializes certain parameters and fields
-- depending on projectileKind.
function Project45GunFire:evalProjectileKind()

  self.updateLaser = function() end

  if self.laser or self.projectileKind ~= "projectile" then

    self.fireMuzzleProjectile = self.fireProjectile

    if self.projectileKind == "summoned" then
      self.updateLaser = hitscanLib.updateSummonAreaIndicator

      activeItem.setScriptedAnimationParameter("isSummonedProjectile", true)
      if self.laser.enabled then
        activeItem.setScriptedAnimationParameter("primaryLaserEnabled", not self.performanceMode)
        activeItem.setScriptedAnimationParameter("primaryLaserColor", self.laser.color)
        activeItem.setScriptedAnimationParameter("primaryLaserWidth", self.laser.width)
      end

    else
      
      -- laser uses the hitscan helper function, so assign that
      self.hitscan = hitscanLib.hitscan
      -- initialize projectile stack
      -- this stack is used by the hitscan functions and the animator
      -- to animate hitscan trails.
      self.projectileStack = {}

      -- laser uses the hitscan function, that's why this logic is in evalProjectileKind()
      if self.laser.enabled then
        self.updateLaser = hitscanLib.updateLaser
        activeItem.setScriptedAnimationParameter("primaryLaserEnabled", not self.performanceMode)    
        activeItem.setScriptedAnimationParameter("primaryLaserColor", self.laser.color)
        activeItem.setScriptedAnimationParameter("primaryLaserWidth", self.laser.width)
      end

      if self.projectileKind == "projectile" then          
        local projectileType = type(self.projectileType) == "table" and self.projectileType[1] or self.projectileType
        local projectileConfig = util.mergeTable(root.projectileConfig(projectileType), self.projectileParameters)
        local projSpeed = projectileConfig.speed or 50
        if root.projectileGravityMultiplier(projectileType) ~= 0 then
          activeItem.setScriptedAnimationParameter("primaryLaserArcSteps", self.laser.trajectoryConfig.renderSteps)
          activeItem.setScriptedAnimationParameter("primaryLaserArcSpeed", projSpeed)
          activeItem.setScriptedAnimationParameter("primaryLaserArcRenderTime", projectileConfig.timeToLive)
          activeItem.setScriptedAnimationParameter("primaryLaserArcGravMult", root.projectileGravityMultiplier(projectileType))
        end
      end
    end
  
  end

  self.muzzleFlashColor = config.getParameter("muzzleFlashColor", {255, 255, 200})
  self.updateProjectileStack = function() end
  if self.projectileKind == "hitscan" then
    self.fireProjectile = hitscanLib.fireHitscan
    self.updateProjectileStack = hitscanLib.updateProjectileStack
    self.hitscanParameters.hitscanColor = self.muzzleFlashColor
  elseif self.projectileKind == "beam" then
    self.muzzleProjectileFired = false
    self.firing = hitscanLib.fireBeam
    self.updateProjectileStack = hitscanLib.updateProjectileStack
    self.beamParameters.beamColor = self.muzzleFlashColor
    activeItem.setScriptedAnimationParameter("beamColor", self.muzzleFlashColor)
  elseif self.projectileKind == "summoned" then
    
    self.muzzlePosition = self.firePosition
    self.firePosition = hitscanLib.summonPosition

    self.muzzleVector = self.aimVector
    self.aimVector = hitscanLib.summonVector
    
    self.muzzleObstructed = function()
      if self.summonedProjectileParameters.summonInTerrain then return true
      elseif self.summonedProjectileParameters.summonAnywhere then
        return world.pointTileCollision(activeItem.ownerAimPosition())
      end
      return world.lineTileCollision(mcontroller.position(), activeItem.ownerAimPosition())      
    end
  end

end

function Project45GunFire:getMovementState()
  local x = 
    (not mcontroller.groundMovement() and "mobile")     or
        (mcontroller.walking()        and "walking")    or 
        (mcontroller.crouching()      and "crouching")  or
    (not mcontroller.running()        and "stationary") or 
                                          "mobile"
  return x
end

-- Returns the reload rating
-- should only be called from the reloading state
function Project45GunFire:reloadRating()
  -- perfect reload can be in a region outside good reload
  if self.reloadTime * self.quickReloadTimeframe[2] <= self.reloadTimer and self.reloadTimer <= self.reloadTime * self.quickReloadTimeframe[3] then
    return PERFECT
  elseif self.reloadTime * self.quickReloadTimeframe[1] <= self.reloadTimer and self.reloadTimer <= self.reloadTime * self.quickReloadTimeframe[4] then
    return GOOD
  else
    return BAD
  end
end

-- Rolls whether the gun fires an additional set of projectiles or not
function Project45GunFire:rollMultishot()
  if not self.multishot then return 1 end
  return project45util.diceroll(self.multishot - math.floor(self.multishot)) and math.ceil(self.multishot) or math.floor(self.multishot)
end

-- Returns the critical multiplier.
-- Typically called when the weapon is about to deal damage.
function Project45GunFire:crit()
  if not self.critChance then return 1 end
  return project45util.diceroll(self.critChance, "Crit: ") and self.critDamageMult or 1
end

-- Calculates the damage per shot of the weapon.
function Project45GunFire:damagePerShot()

  local critDmg = self:crit()
  local lastShotDmg = (storage.ammo <= (self.ammoPerShot or 1) and self.lastShotDamageMult or 1)
  
  return self.baseDamage
  * self.chargeDamage -- up to 2x at full overcharge
  * self.reloadRatingDamage -- as low as 0.8 (bad), as high as 1.5 (perfect)
  * critDmg -- this way, rounds deal crit damage individually
  * lastShotDmg
  / self.projectileCount
end

-- Returns whether the left click is held
function Project45GunFire:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function Project45GunFire:canTrigger()
  return (self.semi and not self.triggered) or not self.semi
end

-- Returns the muzzle of the gun
function Project45GunFire:firePosition(altOverride, addOffset)
  local muzzleOffset = self.weapon.muzzleOffset
  if self.abilitySlot == "alt" or altOverride then
    muzzleOffset = config.getParameter("altMuzzleOffset", self.weapon.muzzleOffset)
  end

  if addOffset then
    muzzleOffset = vec2.add(muzzleOffset, addOffset)
  end

  return vec2.add(
    mcontroller.position(),
    activeItem.handPosition(
      vec2.rotate(
        vec2.add(muzzleOffset, self.weapon.weaponOffset),
        self.weapon.relativeWeaponRotation
      )
    )
  )
end

-- Returns the angle the gun is pointed
-- This is different from the vanilla aim vector, which only takes into account the entity's position
-- and the entity's aim position
function Project45GunFire:aimVector(spread, degAdd, firePosition)
  
  local muzzleOffset = self.weapon.muzzleOffset
  if self.abilitySlot == "alt" then
    muzzleOffset = config.getParameter("altMuzzleOffset", self.weapon.muzzleOffset)
  end

  local firePos = firePosition or self:firePosition()
  local basePos =  vec2.add(
    mcontroller.position(),
    activeItem.handPosition(
      vec2.rotate(
        vec2.add(
          {muzzleOffset[1] - 1, muzzleOffset[2]},
          self.weapon.weaponOffset
        ),
        self.weapon.relativeWeaponRotation
      )
    )
  )
  
  -- world.debugPoint(firePos, "cyan")
  -- world.debugPoint(basePos, "cyan")
  local aimVector = vec2.norm(world.distance(firePos, basePos))
  aimVector = vec2.rotate(aimVector, sb.nrand((util.toRadians(spread or 0)), 0) + util.toRadians(degAdd or 0))
  return aimVector
end

function Project45GunFire:muzzleObstructed()
  return world.lineTileCollision(mcontroller.position(), self:firePosition())
end

function Project45GunFire:saveGunState()
  
  local newGunAnimState = {
    jammed="jammed",
    idle="idle",
    open="open",
    ejected="ejected",

    ejecting = "ejected",
    boltPulling = "ejected",
    
    feeding = "idle",
    boltPushing = "idle",

    firing = "idle",
    firingLoop = "idle",
    fired = "fired",
    
    unjamming = storage.jamAmount > 0 and "jammed" or "idle",
  }

  local gunState = {
    chamber = animator.animationState("chamber"),
    bolt = animator.animationState("bolt"),
    gunAnimation = newGunAnimState[animator.animationState("gun")],
    ammo = storage.ammo,
    reloadRating = storage.reloadRating,
    unejectedCasings = storage.unejectedCasings,
    jamAmount = storage.jamAmount,
    savedProjectileIndex = storage.savedProjectileIndex,
    loadSuccess = true
  }
  activeItem.setInstanceValue("savedGunState", gunState)
end

function Project45GunFire:loadGunState()

  local loadedGunState = config.getParameter("savedGunState", {
    chamber = "empty",
    bolt = "open",
    gunAnimation = self.breakAction and "open" or "ejected",
    ammo = -1,
    reloadRating = OK,
    unejectedCasings = 0,
    jamAmount = 0,
    savedProjectileIndex = 1,
    loadSuccess = false
  })

  if not loadedGunState.loadSuccess then
    sb.logInfo("WARNING: GUN STATE NOT LOADED")
  end

  animator.setAnimationState("chamber", loadedGunState.chamber)
    
  storage.ammo = storage.ammo or loadedGunState.ammo
  storage.savedProjectileIndex = storage.savedProjectileIndex or loadedGunState.savedProjectileIndex
  storage.reloadRating = storage.reloadRating or loadedGunState.reloadRating
  activeItem.setScriptedAnimationParameter("reloadRating", reloadRatingList[storage.reloadRating])
  storage.unejectedCasings = storage.unejectedCasings or loadedGunState.unejectedCasings
  
  storage.jamAmount = storage.jamAmount or loadedGunState.jamAmount
  activeItem.setScriptedAnimationParameter("jamAmount", storage.jamAmount)
  animator.setAnimationState("bolt", loadedGunState.bolt)
  
  if loadedGunState.bolt == "open" then
    loadedGunState.gunAnimation = (self.breakAction and not loadedGunState.loadSuccess) and "open" or "ejected"
  end
  
  animator.setAnimationState("gun", loadedGunState.gunAnimation)

end

-- SECTION: HELPER FUNCTIONS

function Project45GunFire:setStance(stance, snap)

  if stance.disabled then return end

  if not stance.validated then
    stance.weaponRotation = stance.weaponRotation or 0
    stance.armRotation = stance.armRotation or 0
    stance.twoHanded = stance.twoHanded == nil and true or stance.twoHanded
    stance.validated = true
  end

  stance = copy(stance)
  
  snap = snap or stance.lock or stance.snap
  -- get old stance, plus rotations, for smooth stance transition
  local oldStance = nil
  if not snap and self.weapon.stance and not stance.lite then
    oldStance = sb.jsonMerge(self.weapon.stance, {})
    oldStance.weaponRotation = util.toDegrees(self.weapon.relativeWeaponRotation)
    oldStance.armRotation = util.toDegrees(self.weapon.relativeArmRotation)
  end
  
  -- set stance
  self.stanceLocked = stance.lock
  activeItem.setTwoHandedGrip(stance.twoHanded or false)

  if not stance.lite
  or not self.weapon.stance
  then
    self.weapon:setStance(stance)
  else
    self.weapon.stance = copy(self.weapon.stance)
    for stateType, state in pairs(stance.animationStates or {}) do
      animator.setAnimationState(stateType, state)
    end
  
    for _, soundName in pairs(stance.playSounds or {}) do
      animator.playSound(soundName)
    end
  
    for _, particleEmitterName in pairs(stance.burstParticleEmitters or {}) do
      animator.burstParticleEmitter(particleEmitterName)
    end
    self.weapon.stance.frontArmFrame = stance.frontArmFrame
    self.weapon.stance.backArmFrame = stance.backArmFrame
    activeItem.setFrontArmFrame(stance.frontArmFrame)
    activeItem.setBackArmFrame(stance.backArmFrame)
  end

  -- flip weapon
  --[[
  if stance.flipWeapon then
    animator.setGlobalTag("directives", "?flipy")
  else
    animator.setGlobalTag("directives", "")
  end
  --]]

  -- reset weapon's rotations to those of old stance for smooth stance transition
  if not snap and oldStance and not stance.lite then
    self.weapon.relativeArmRotation = util.toRadians(oldStance.armRotation)
    self.weapon.relativeWeaponRotation = util.toRadians(oldStance.weaponRotation)
  end

  -- function Project45GunFire:recoil(down, mult, amount, recoverDelay)
  if stance.armRecoil then
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(stance.armRecoil)
  end
  if stance.weaponRecoil then
    self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(stance.weaponRecoil)
  end

  storage.stanceProgress = 0
end

function Project45GunFire:debugFunction()
  
  if not self.debug then return end

  self:discardCasings(1)
  animator.burstParticleEmitter("magazine")

end

--[[
-- Chooses a random projectile from a weighted list of projectiles.
-- Weights can either be percentages (represented by a float between 0 and 1 inclusive)
-- or discrete (represented by an integer)
function chooseRandomProjectile(projectileList, discreteOdds)
  local totalWeight = 0
  if discreteOdds then
    -- each projectileData is {projectileWeightOrChance, projectileType}
    for _, projectileData in ipairs(projectileList) do
        totalWeight = totalWeight + projectileList[1]
    end
  end

  -- Generate a random number within the range of totalWeight
  local randomValue = math.random(discreteOdds and totalWeight or nil)

  -- Find the projectile corresponding to the randomValue
  -- Return the index number
  local cumulativeOdds = 0
  for i, projectileData in ipairs(projectileList) do
      cumulativeOdds = cumulativeOdds + projectileData[1]
      if randomValue <= cumulativeOdds then
          return i
      end
  end
end
--]]

-- SECTION: Legacy Functions

function GunFire:init()
  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function() end
end

function Project45GunFire:cooldown()
  -- disable gunfire cooldown of alt abilities
end

function Project45GunFire:energyPerShot()
  return 0
end

function Project45GunFire:auto()
  if storage.ammo <= 0
  or self.ammoPerShot > storage.ammo
  or storage.jamAmount > 0
  then
    -- animator.playSound("click")
    self.cooldownTimer = self.fireTime
    return
  end
  
  self:fireProjectile()
  self:muzzleFlash()
  self:screenShake(self.screenShakeAmount)
  self:recoil(nil, nil, self.recoilAmount)
  self:updateAmmo(-(self.ammoPerShot or 1))

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
end


function Project45GunFire:burst()
  
  if storage.ammo <= 0
  or self.ammoPerShot > storage.ammo
  or storage.jamAmount > 0
  then
    -- animator.playSound("click")
    self.cooldownTimer = self.fireTime
    return
  end
  
  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    
    self:fireProjectile()
    self:muzzleFlash()
    shots = shots - 1
    self:screenShake(self.screenShakeAmount)
    self:recoil(nil, nil, self.recoilAmount)
    
    self:updateAmmo(-(self.ammoPerShot or 1))
    if storage.ammo <= 0
    or self.ammoPerShot > storage.ammo
    then break end

    util.wait(self.burstTime)
  end

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function Project45GunFire:altMuzzleFlash()
  if not self.hidePrimaryMuzzleFlash then
    animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
    animator.setAnimationState("firing", "fire")
    animator.setLightActive("muzzleFlash", true)
  end

  if self.useAltMuzzleFlash then
    animator.setPartTag("altMuzzleFlash", "variant", math.random(1, 3))
    animator.setAnimationState("altfiring", "fire")
    animator.setLightActive("altMuzzleFlash", true)
    storage.altMuzzleFlashTimer = self.muzzleFlashTime or 0.05
  end
  
  if self.useParticleEmitter == nil or self.useParticleEmitter then
    animator.burstParticleEmitter("altMuzzleFlash", true)
  end

  if self.usePrimaryFireSound then
    animator.playSound("fire")
  else
    animator.playSound("altFire")
  end
end