require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/project45/hitscanLib.lua"

local BAD, OK, GOOD, PERFECT = 1, 2, 3, 4
local reloadRatingList = {"BAD", "OK", "GOOD", "PERFECT"}
local debugTime = 0.5

Project45GunFire = WeaponAbility:new()

function Project45GunFire:init()

  -- INITIALIZATIONS
  self.debugTimer = debugTime
  self.isFiring = false
  
  -- evaluate whether the user is an NPC
  self.usedByNPC = world.entityType(activeItem.ownerEntityId())
  
  -- separate cock time and reload time
  self.reloadTime = self.reloadTime * 0.8
  self.reloadTimer = -1

  -- initialize charge frame
  self.chargeFrame = 1

  -- initialize charge damage
  self.chargeDamage = 1

  -- initialize burst counter
  storage.burstCounter = storage.burstCounter or self.burstCount

  -- VALIDATIONS

  -- SETTING VALIDATIONS: These validations serve to reduce firing conditions and allow consistent logic.

  -- self.autoFireOnFullCharge only matters if the gun is semifire
  -- if an autofire gun is the kind that's charged, the charge is essentially it winding up.
  self.autoFireOnFullCharge = self.semi and self.autoFireOnFullCharge

  -- self.fireBeforeOvercharge only matters if the gun is auto
  -- NOTE: Should this be hardcoded? If this setting is false,
  -- then the gun only autofires at max charge, defeating the purpose of
  -- the overcharge providing bonus damage...
  -- Unless the gun continues firing until the gun is undercharged. (Should this be implemented?)
  -- self.fireBeforeOvercharge = not self.semi and self.fireBeforeOvercharge
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

  self.bulletsPerReload = math.max(1, self.bulletsPerReload)

  -- let inaccuracy be a table
  if type(self.inaccuracy) ~= "table" then
    self.inaccuracy = {
      mobile = self.inaccuracy*2,  -- double inaccuracy while running
      walking = self.inaccuracy,  -- standard inaccuracy while walking
      stationary = self.inaccuracy/2, -- halved inaccuracy while standing
      crouching = 0 -- nil inaccuracy while crouching
    }
  end
  self.currentInaccuracy = self.inaccuracy.mobile

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

  -- initialize animation stuff
  
  activeItem.setScriptedAnimationParameter("reloadTimer", -1)
  activeItem.setScriptedAnimationParameter("chargeTimer", 0)
  activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
  
  activeItem.setScriptedAnimationParameter("reloadTime", self.reloadTime)
  activeItem.setScriptedAnimationParameter("quickReloadTimeframe", self.quickReloadTimeframe)

  activeItem.setScriptedAnimationParameter("chargeTime", self.chargeTime)
  activeItem.setScriptedAnimationParameter("overchargeTime", self.overchargeTime)

  self:evalProjectileKind()
  self:updateMagVisuals()
  self:updateChamberState()


  -- Final touches before use

  self.stances = self.stances or {}
  self.stances.aimStance = self.stances.aimStance or {
    weaponRotation = 0,
    armRotation = 0,
    twoHanded = config.getParameter("twoHanded", false),
    allowRotate = true,
    allowFlip = true
  }

  self.weapon:setStance(self.stances.aimStance)
  self:screenShake()
  if storage.jamAmount > 0 then
    self:setState(self.jammed)
  end
  self:recoil(true, 4) -- you're bringing the gun up

end

function Project45GunFire:update(dt, fireMode, shiftHeld)

  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  -- update timers
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  -- update relevant stuff
  self:updateDebugTimer()
  self:updateLaser()
  self:updateCharge()
  self:updateStance()
  self:updateCycleTime()
  self:updateProjectileStack()
  self:updateMovementControlModifiers()
  self:updateMuzzleFlash()

  if self.debugTimer <= 0 then
    self:debugFunction()
    self.debugTimer = debugTime
  end

  -- Prevent energy regen if there is energy or if currently reloading
  if storage.ammo > 0 or self.reloadTimer > 0 or not status.resourceLocked("energy") then
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
  -- TODO: activeItem.setCursor("/cursors/project45reticle" .. x .. ".cursor")

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
      else
        
        if storage.ammo == 0 and not self.triggered then
            self:ejectMag()
        elseif not self.triggered then
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
end

-- STATE FUNCTIONS

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
end

function Project45GunFire:firing()
  
  self.triggered = self.semi or storage.ammo == 0

  if self:jam() then return end
  -- don't fire when muzzle collides with terrain
  -- if not self.projectileParameters.hitscanIgnoresTerrain and world.lineTileCollision(mcontroller.position(), self:firePosition()) then
  if self:muzzleObstructed() then
    self:stopFireLoop()
    self.isFiring = false
    return
  end
  

  self.isFiring = true
  animator.setAnimationState("gun", "firing")

  -- reset burst count if already max
  storage.burstCounter = (storage.burstCounter >= self.burstCount) and 0 or storage.burstCounter

  self:startFireLoop()
  
  self:applyInaccuracy()

  for i = 1, self.projectileCount * self:rollMultishot() do
    self:fireProjectile()
  end
  self:muzzleFlash()
  self:screenShake()
  self:recoil()

  storage.burstCounter = storage.burstCounter + 1

  if self.resetChargeOnFire then self.chargeTimer = 0 end

  -- add unejected casings

  storage.unejectedCasings = math.min(storage.unejectedCasings + self.ammoPerShot, storage.ammo)
  self:updateAmmo(diceroll(self.ammoConsumeChance) and -self.ammoPerShot or 0)
  
  self.triggered = storage.ammo == 0 or self.triggered

  
  self:updateChamberState("filled")
  
  -- if not a manual feed gun
  -- or if the gun's not done bursting
  -- then eject immediately
  if storage.ammo > 0
  and (not self.manualFeed
  or storage.burstCounter < self.burstCount)
  then
    if self.ejectCasingsAfterBurst
    and storage.burstCounter < self.burstCount
    then
      util.wait(self.currentCycleTime)
      self:setState(self.firing)
    else
      util.wait(self.currentCycleTime/3)
      self:setState(self.ejecting)
    end
  -- otherwise, stop the cycle process
  else
    self:stopFireLoop()
    self.cooldownTimer = self.fireTime
    self.isFiring = false
  end
end

function Project45GunFire:ejecting()

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

  -- otherwise, the gun is either semiauto
  -- or not done bursting; we eject (faster animation)
  else
    animator.setAnimationState("gun", "ejecting")
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
  else
    util.wait(self.currentCycleTime/3)
  end

  if not self.ejectCasingsWithMag then
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
    if self.ejectMagOnEmpty then
      self:ejectMag()
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
    animator.setAnimationState("bolt", "closed")
    self:updateChamberState("ready")
    self.isCocking = false
    if self.chargeTime + self.overchargeTime > 0 then
      self:setState(self.charging)
    else
      self:setState(self.firing)      
    end
    return
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
  --[[
  if self.chargeTime + self.overchargeTime > 0 and self:triggering() then
    self.triggered = self.semi or self.reloadTimer >= 0 or self.manualFeed
  else
    self.triggered = self.semi or self.reloadTimer >= 0
  end
  --]]
  self.reloadTimer = -1  -- mark end of reload
  activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)
  self.isFiring = false
end

function Project45GunFire:reloading()
  
  self.reloadTimer = 0 -- mark begin of reload
  animator.playSound("reloadStart") -- sound of mag being grabbed

  self.triggered = true  -- prevent accidentally reloading instantly
  
  -- general reload rating calculation vars
  local sumRating = 0
  local reloads = 0

  -- visual stuff
  -- dictates appearance of reload ui
  -- and presence of mag (conditionally)
  local displayResetTimer = 0
  local displayResetTime = self.reloadTime / 2
  activeItem.setScriptedAnimationParameter("reloadRating", "")
  if storage.ammo < 0 then storage.ammo = 0 end

  -- begin minigame
  -- self.weapon:setStance(self.stances.reloading)
  while self.reloadTimer <= self.reloadTime do
    activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)

    if displayResetTimer <= 0 and storage.ammo < self.maxAmmo then
      activeItem.setScriptedAnimationParameter("reloadRating", "")
      if self.internalMag then
        animator.setAnimationState("magazine", "present") -- insert mag, hiding it from view
      end
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
        animator.playSound("perfectReload")
        sumRating = sumRating + 2
      end

      self.triggered = true
      
      -- update ammo
      self:updateAmmo(self.bulletsPerReload)

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
  
  
  animator.setAnimationState("magazine", self.internalMag and "absent" or "present")
  
  -- if there hasn't been any input, just load round
  if storage.ammo < self.maxAmmo then
    sumRating = sumRating + 0.5 -- OK: 0.5
    reloads = reloads + 1 -- we did a reload
    animator.playSound("loadRound")
    if self.ejectMagOnReload then
      animator.burstParticleEmitter("magazine") -- throw mag strip
    end
    self:updateAmmo(self.bulletsPerReload)
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
  storage.reloadRating = finalReloadRating
  activeItem.setScriptedAnimationParameter("reloadRating", reloadRatingList[finalReloadRating])
  self.reloadRatingDamage = self.reloadRatingDamageMults[storage.reloadRating]
  animator.playSound("reloadEnd")  -- sound of magazine inserted
  -- self.weapon:setStance(self.stances.reloaded)
  self:setState(self.cocking)
  
end

function Project45GunFire:cocking()

  self.cooldownTimer = self.fireTime
  self.isCocking = true

  if animator.animationState("bolt") == "closed"
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
  self:recoil(true) -- TODO: make me a stance
  animator.setAnimationState("gun", "unjamming") -- should transist back to being jammed
  animator.playSound("unjam")
  self:updateJamAmount(math.random() * -1)
  if storage.jamAmount <= 0 then
    -- animator.playSound("click")
    self.reloadTimer = self.reloadTime
    animator.setAnimationState("bolt", "closed")
    animator.setAnimationState("chamber", "filled")
    self:setState(self.cocking)
    return
  end
end

-- ACTION FUNCTIONS

-- Returns true if the weapon successfully jammed.
function Project45GunFire:jam()
  if diceroll(self.jamChances[storage.reloadRating]) then

    self:stopFireLoop()
    animator.playSound("jam")
    
    animator.setAnimationState("bolt", "jammed")
    self:updateChamberState("filled")
    storage.unejectedCasings = math.min(storage.ammo, storage.unejectedCasings + self.ammoPerShot)
    self:updateAmmo(-self.ammoPerShot)
    
    -- prevent triggering and firing
    self.triggered = true
    self.screenShakeTimer = 0
    storage.burstCounter = self.burstCount
    self.chargeTimer = self.resetChargeOnJam and 0 or self.chargeTimer
    
    self:updateJamAmount(1, true)
    self:setState(self.jammed)
    return true
  end
  return false
end
--[[
function Project45GunFire:beginAim()
  -- get previous weapon stance
  local prevStance = self.weapon.stance
  if not prevStance then return end

  -- set stance to aiming stance
  self.weapon:setStance(self.stances.aimStance)

  -- revert weapon stance manually
  self.weapon.weaponOffset = prevStance.weaponOffset or {0, 0}
  -- self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  self.weapon.relativeWeaponRotation = util.toRadians(prevStance.weaponRotation)
  self.weapon.relativeArmRotation = util.toRadians(prevStance.armRotation)

  -- restart stance progress
  storage.stanceProgress = 0
end
--]]

function Project45GunFire:muzzleFlash()
  if self.projectileKind ~= "beam" then
    -- play fire and hollow sound if the gun isn't firing a beam
    animator.setSoundPitch("fire", sb.nrand(0.01, 1))
    animator.setSoundVolume("hollow", (1 - storage.ammo/self.maxAmmo) * self.hollowSoundMult)
    animator.playSound("fire")
    animator.playSound("hollow")
  end
  animator.setLightActive("muzzleFlash", true)
  animator.burstParticleEmitter("muzzleFlash")
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setPartTag("muzzleFlash", "directives", string.format("?fade=%02X%02X%02X",self.muzzleFlashColor[1], self.muzzleFlashColor[2], self.muzzleFlashColor[3]) .. "=1")
  animator.setAnimationState("flash", "flash")
  self.muzzleFlashTimer = self.muzzleFlashTime or 0.05
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

function Project45GunFire:fireProjectile(projectileType)
      
  self.projectileParameters.power = self:damagePerShot()
  
  local projectileId = world.spawnProjectile(
    projectileType or self.projectileType,
    self:firePosition(),
    activeItem.ownerEntityId(),
    self:aimVector(0),
    false,
    self.projectileParameters
  )
  
end

-- Ejects casings, purely virtual
function Project45GunFire:discardCasings(debug)

  if debug then
    animator.setParticleEmitterBurstCount("ejectionPort", 1)
    animator.burstParticleEmitter("ejectionPort")
    return
  end

  if storage.unejectedCasings > 0 then
    animator.setParticleEmitterBurstCount("ejectionPort", storage.unejectedCasings)
    animator.burstParticleEmitter("ejectionPort")
    storage.unejectedCasings = 0
  end
end

-- Nudges arm before shooting
function Project45GunFire:applyInaccuracy()
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + math.abs(sb.nrand(self.currentInaccuracy, 0))
  storage.stanceProgress = 0
end

-- Kicks gun muzzle up and backward, shakes screen
function Project45GunFire:recoil(down, mult)
  local mult = mult or self.recoilMult
  mult = down and -mult or mult
  self.weapon.relativeWeaponRotation = math.min(self.weapon.relativeWeaponRotation, util.toRadians(self.maxRecoilDeg / 2)) + util.toRadians(self.recoilAmount * mult)
  self.weapon.relativeArmRotation = math.min(self.weapon.relativeArmRotation, util.toRadians(self.maxRecoilDeg / 2)) + util.toRadians(self.recoilAmount * mult)
  self.weapon.weaponOffset = {-0.1, 0}
  storage.stanceProgress = 0
end

-- Ejects mag
-- can immediately begin reloading minigame
function Project45GunFire:ejectMag()

  if not status.overConsumeResource("energy", status.resourceMax("energy") * self.reloadCost) then
    animator.playSound("click")
    return
  end

  self.triggered = true
  storage.burstCounter = 0

  if not self.ejectMagOnEmpty then
    self:screenShake()
    self:recoil(true)
  end
  
  -- audiovisually eject mag if it isn't an internal mag
  animator.setAnimationState("magazine", "absent")
  animator.playSound("eject")
  animator.burstParticleEmitter("magazine")

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
  if self.usedByNPC then return end
  local source = mcontroller.position()
  local shake_dir = vec2.mul(self:aimVector(0), amount or self.currentScreenShake or 0.1)
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

-- ___________________________________________________________[ UPDATE FUNCTIONS ] ___________________________________________________________

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


  if self.chargeTimer > 0 then
    animator.setAnimationState("charge", self.progressiveCharge and "chargingProg" or "charging")
  else
    animator.setAnimationState("charge", "off")
  end


  -- update current charge frame (1 to n)
  if self.progressiveCharge then
    self.chargeFrame = math.max(1, math.ceil(self.chargeFrames * (self.chargeTimer / (self.chargeTime + self.overchargeTime))))
    animator.setGlobalTag("chargeFrame", self.chargeFrame)
  end

end

-- Updates the gun's ammo:
-- Sets the gun's stored ammo count 
-- and updates the animation parameter.
-- If not setting the value, the ammo is clamped
-- between 0 and max ammo.
function Project45GunFire:updateAmmo(delta, willReplace)
  storage.ammo = willReplace and delta or clamp(storage.ammo + delta, 0, self.maxAmmo)
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

  local ammoFrame
  if self.magVisualPercentage then
    local ammoPercent = math.ceil(storage.ammo * 100 / self.maxAmmo)
    ammoFrame = "present." .. math.floor(ammoPercent * self.magFrames)
  else
    if storage.ammo >= self.magAmmoRange[2] then
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
  storage.jamAmount = set and delta or clamp(storage.jamAmount + delta, 0, 1)
  activeItem.setScriptedAnimationParameter("jamAmount", storage.jamAmount)
end

--[[
-- this is honestly unsafe imo.
-- While this function could be used for `updateAmmo()` and `updateJamAmount()`
-- some scripted animation parameters may need to be named differently, depending on whether
-- ammo or jamAmount is used by an alt ability.
-- Unlikely, but I'm not taking any chances.
function Project45GunFire:updateIndicatedVariable(var, delta, set, clampMin, clampMax):
  storage[var] = set and delta or clamp(storage[var] + delta, clampMin, clampMax)
  activeItem.setScriptedAnimationParameter(var, storage[var])
end
--]]

function Project45GunFire:updateCycleTime()
  -- don't bother updating cycle time if cycleTimeProgress wasn't even instantiated
  -- or if there's no difference between the cycle times
  -- this means that the cycle time is expected to be constant
  if not self.cycleTimer
  or self.cycleTimeDiff == 0
  then return end

  if self.triggering() and not self.triggered then
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
  if not self.screenShakeTimer then return end

  if self.triggering() and not self.triggered then
    self.screenShakeTimer = math.min(self.screenShakeTimer + self.dt, self.screenShakeMaxTime)
  else
    self.screenShakeTimer = math.max(0, self.screenShakeTimer - self.dt)
  end
  
  local screenShakeProgress = self.screenShakeTimer / self.screenShakeMaxTime
  
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
  if self.muzzleFlashTimer <= 0 then
    animator.setLightActive("muzzleFlash", false)
  end
end

-- updates the weapon's stance
-- interpolates the weapon's stance to the stance set via self.weapon:setStance()
function Project45GunFire:updateStance()

  if self.weapon.stance ~= self.stances.aimStance then return end

  local offset_i = self.weapon.weaponOffset
  local offset_o = self.weapon.stance.weaponOffset or {0, 0}

  self.weapon.weaponOffset = {
    interp.sin(storage.stanceProgress, offset_i[1], offset_o[1]),
    interp.sin(storage.stanceProgress, offset_i[2], offset_o[2])
  }
  self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())    
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
  
  --[[
  for x, y in pairs(self.inaccuracy) do
    if y == self.currentInaccuracy then
      activeItem.setCursor("/cursors/project45reticle" .. x .. ".cursor")
      break
    end
  end
  --]]
end

-- EVAL FUNCTIONS

-- Replaces certain functions and initializes certain parameters and fields
-- depending on projectileKind.
function Project45GunFire:evalProjectileKind()
  
  if self.laser or self.projectileKind ~= "projectile" then
    -- laser uses the hitscan helper function, so assign that
    self.hitscan = hitscanLib.hitscan
    self.updateLaser = function() end
    -- initialize projectile stack
    -- this stack is used by the hitscan functions and the animator
    -- to animate hitscan trails.
    self.projectileStack = {}

    -- laser uses the hitscan function, that's why this logic is in evalProjectileKind()
    if self.laser.enabled then
      self.updateLaser = hitscanLib.updateLaser
      activeItem.setScriptedAnimationParameter("primaryLaserEnabled", true)    
      activeItem.setScriptedAnimationParameter("primaryLaserColor", self.laser.color)
      activeItem.setScriptedAnimationParameter("primaryLaserWidth", self.laser.width)

      if self.projectileKind == "projectile" then
        
        local projectileConfig = util.mergeTable(root.projectileConfig(self.projectileType), self.projectileParameters)
        local projSpeed = projectileConfig.speed
        
        if root.projectileGravityMultiplier(self.projectileType) ~= 0 and projectileConfig.speed then
          activeItem.setScriptedAnimationParameter("primaryLaserArcSpeed", projectileConfig.speed)
          activeItem.setScriptedAnimationParameter("primaryLaserArcRenderTime", projectileConfig.timeToLive)
          activeItem.setScriptedAnimationParameter("primaryLaserArcGravMult", root.projectileGravityMultiplier(self.projectileType))
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
    self.firing = hitscanLib.fireBeam
    self.updateProjectileStack = hitscanLib.updateProjectileStack
    self.beamParameters.beamColor = self.muzzleFlashColor
    activeItem.setScriptedAnimationParameter("beamColor", self.muzzleFlashColor)
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

function Project45GunFire:rollMultishot()
  return diceroll(self.multishot - math.floor(self.multishot)) and math.floor(self.multishot) or math.ceil(self.multishot)
end

-- Returns the critical multiplier.
-- Typically called when the weapon is about to deal damage.
function Project45GunFire:crit()
  return diceroll(self.critChance, "Crit: ") and self.critDamageMult or 1
end

-- Calculates the damage per shot of the weapon.
function Project45GunFire:damagePerShot(isHitscan)

  local critDmg = self:crit()
  local lastShotDmg = (storage.ammo <= self.ammoPerShot and self.lastShotDamageMult or 1)

  return self.baseDamage
  * activeItem.ownerPowerMultiplier()
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
function Project45GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(vec2.add(self.weapon.muzzleOffset, self.weapon.weaponOffset), self.weapon.relativeWeaponRotation)))
end

-- Returns the angle the gun is pointed
-- This is different from the vanilla aim vector, which only takes into account the entity's position
-- and the entity's aim position
function Project45GunFire:aimVector(spread)
  local firePos = self:firePosition()
  local basePos =  vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(vec2.add({self.weapon.muzzleOffset[1] - 1, self.weapon.muzzleOffset[2]}, self.weapon.weaponOffset), self.weapon.relativeWeaponRotation)))
  -- world.debugPoint(firePos, "cyan")
  -- world.debugPoint(basePos, "cyan")
  local aimVector = vec2.norm(world.distance(firePos, basePos))
  aimVector = vec2.rotate(aimVector, sb.nrand((spread or 0), 0))
  return aimVector
end

function Project45GunFire:muzzleObstructed()
  return world.lineTileCollision(mcontroller.position(), self:firePosition())
end

function Project45GunFire:saveGunState()
  
  local newGunAnimState = {
    jammed="jammed",
    idle="idle",
    ejected="ejected",

    ejecting = "ejected",
    boltPulling = "ejected",
    
    feeding = "idle",
    boltPushing = "idle",

    firing = "idle",
    firingLoop = "idle",
    
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
    loadSuccess = true
  }
  activeItem.setInstanceValue("savedGunState", gunState)
end

function Project45GunFire:loadGunState()

  local loadedGunState = config.getParameter("savedGunState", {
    chamber = "empty",
    bolt = "closed",
    gunAnimation = "idle",
    ammo = 0,
    reloadRating = OK,
    unejectedCasings = 0,
    jamAmount = 0,
    loadSuccess = false
  })

  if not loadedGunState.loadSuccess then
    sb.logInfo("WARNING: GUN STATE NOT LOADED")
  end

  animator.setAnimationState("chamber", loadedGunState.chamber)
    
  storage.ammo = storage.ammo or loadedGunState.ammo
  storage.reloadRating = storage.reloadRating or loadedGunState.reloadRating
  activeItem.setScriptedAnimationParameter("reloadRating", reloadRatingList[storage.reloadRating])
  storage.unejectedCasings = storage.unejectedCasings or loadedGunState.unejectedCasings
  
  storage.jamAmount = storage.jamAmount or loadedGunState.jamAmount
  activeItem.setScriptedAnimationParameter("jamAmount", storage.jamAmount)

  if not loadedGunState.loadSuccess then
    animator.setAnimationState("bolt", loadedGunState.bolt)
    animator.setAnimationState("gun", loadedGunState.gunAnimation)
  end

end

-- HELPER FUNCTIONS

--[[
function SynthetikMechanics:setStance(stance, snap)

  if stance.disabled then return end

  local oldStance = nil
  if not snap and self.weapon.stance then
    oldStance = sb.jsonMerge(self.weapon.stance, {})
    oldStance.weaponRotation = util.toDegrees(self.weapon.relativeWeaponRotation)
    oldStance.armRotation = util.toDegrees(self.weapon.relativeArmRotation)
  end
  
  self.weapon:setStance(stance)

  if stance.flipWeapon then
    animator.setGlobalTag("directives", "?flipy")
  else
    animator.setGlobalTag("directives", "")
  end

  if not snap and oldStance then
    self.weapon.relativeArmRotation = util.toRadians(oldStance.armRotation)
    self.weapon.relativeWeaponRotation = util.toRadians(oldStance.weaponRotation)
  end
  storage.aimProgress = 0
end

function SynthetikMechanics:snapStance(stance)
  self.weapon.relativeWeaponRotation = math.rad(stance.weaponRotation)
  self.weapon.relativeArmRotation = math.rad(stance.armRotation)
  storage.aimProgress = 0
end
--]]

function Project45GunFire:debugFunction()

end

function diceroll(chance)
  return math.random() <= chance
end

function clamp(x, min, max)
  if x < min then
    return min
  elseif x > max then
    return max
  else
    return x
  end
end