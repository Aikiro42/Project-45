require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/project45/hitscanLib.lua"

-- TODO: find a way to use animator.setGlobalTag and animator.setPartTag

local BAD, OK, GOOD, PERFECT = 1, 2, 3, 4
local reloadRatingList = {"BAD", "OK", "GOOD", "PERFECT"}

Project45GunFire = WeaponAbility:new()

function Project45GunFire:init()

  -- INITIALIZATIONS

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
  self.burstCounter = 0

  -- VALIDATIONS

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


  -- initialize animation timer if charge is not progressive i.e. looping
  if not self.progressiveCharge then
    self.chargeAnimationTime = self.currentCycleTime/3
    self.chargeAnimationTimer = 0
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
  storage.ammo = math.min(self.maxAmmo, storage.ammo or config.getParameter("currentAmmo", self.maxAmmo))
  storage.stanceProgress = 0 -- stance progres is stored in storage so that other weapons may recoil the gun
  storage.unejectedCasings = storage.unejectedCasings or 0
  storage.reloadRating = storage.reloadRating or config.getParameter("currentReloadRating", OK)

  self.reloadRatingDamage = self.reloadRatingDamageMults[storage.reloadRating]

  storage.jamAmount = config.getParameter("currentJamAmount", 0)

  -- initialize timers
  self.chargeTimer = 0
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

  --[[
  -- TODO: Make trajectory laser work
  if not self.projectileParameters.speed and self.projectileKind == "projectile" then
    local projConfig = root.projectileConfig(self.projectileType)
    if projConfig.physics == "grenade" then
      self.projectileParameters.speed = projConfig.speed
    end
  end
  activeItem.setScriptedAnimationParameter("primaryProjectileSpeed", self.projectileParameters.speed)
  --]]


  -- Final touches before use

  self.stances = self.stances or {}
  self.stances.aimStance = {
    weaponRotation = 0,
    armRotation = 0,
    twoHanded = config.getParameter("twoHanded", false),
    allowRotate = true,
    allowFlip = true
  }

  self.weapon:setStance(self.stances.aimStance)
  self:recoil(true, 4) -- you're bringing the gun up

end

function Project45GunFire:update(dt, fireMode, shiftHeld)

  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  -- update timers
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  -- update relevant stuff
  self:updateCharge()
  self:updateStance()
  self:updateCycleTime()
  self:updateProjectileStack()
  self:updateMovementControlModifiers()
  self:updateMuzzleFlash()

  -- Prevent energy regen if there is energy or if currently reloading
  if storage.ammo > 0 or self.reloadTimer > 0 or not status.resourceLocked("energy") then
    status.setResource("energyRegenBlock", 1)
  end

  if not self:triggering() then
    self.triggered = false
    self:stopFireLoop()
    if self.queuedFire then
      self.queuedFire = false
      self:setState(self.firing)
    end
  end
  
  
  -- accuracy settings
  local movementState = self:getMovementState()
  self.currentInaccuracy = self.inaccuracy[movementState]
  self.currentRecoverTime = self.recoverTime[movementState]
  -- activeItem.setCursor("/cursors/project45reticle" .. x .. ".cursor")

  -- trigger i/o logic
  -- TODO: check my logic
  if self:triggering()
  and not self.weapon.currentAbility
  and self.cooldownTimer == 0
  and not self.beamFiring
  then

    if storage.jamAmount <= 0 then

      if storage.ammo > 0 then

        if not self:jam() then

          if animator.animationState("chamber") == "ready"
          and not self.triggered then
            -- don't fire when obstructed
            if not self:muzzleObstructed() then
              if self.chargeTime + self.overchargeTime == 0
              or self.fireBeforeOvercharge and self.chargeTimer >= self.chargeTime
              or self.autoFireOnFullCharge and self.chargeTimer >= self.chargeTime + self.overchargeTime then
                self:setState(self.firing)
              elseif self.chargeTimer >= self.chargeTime then
                self.queuedFire = true
              end
            end
            
          elseif animator.animationState("chamber") == "filled"
          and not (self.semi and self.triggered)
          then
            self:setState(self.ejecting)
          elseif not self.triggered then
            self:setState(self.cocking)
          end

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
  activeItem.setInstanceValue("currentAmmo", storage.ammo)
  activeItem.setInstanceValue("currentJamAmount", storage.jamAmount)
  activeItem.setInstanceValue("currentReloadRating", storage.reloadRating)
end

-- STATE FUNCTIONS

function Project45GunFire:firing()
  
  self.triggered = self.semi or storage.ammo == 0
  self.queuedFire = not self.semi and self.queuedFire and storage.ammo > 0

  -- reset burst count if already max
  self.burstCounter = self.burstCounter >= self.burstCount and 0 or self.burstCounter

  -- don't fire when muzzle collides with terrain
  -- if not self.projectileParameters.hitscanIgnoresTerrain and world.lineTileCollision(mcontroller.position(), self:firePosition()) then
  if self:muzzleObstructed() then
    self:stopFireLoop()
    return
  end

  self:startFireLoop()
  
  self:applyInaccuracy()

  for i = 1, self.projectileCount * self:rollMultishot() do
    self:fireProjectile()
  end
  self:muzzleFlash()
  self:recoil()

  self.burstCounter = self.burstCounter + 1

  if self.resetChargeOnFire then self.chargeTimer = 0 end

  -- add unejected casings
  self:updateAmmo(-self.ammoPerShot)
  if storage.ammo == 0 then self.triggered = true end
  storage.unejectedCasings = math.min(storage.unejectedCasings + self.ammoPerShot, storage.ammo)

  -- if not a manual feed gun
  -- or if the gun's not done bursting
  -- then eject immediately
  if not self.manualFeed
  or self.burstCounter < self.burstCount
  then
    util.wait(self.currentCycleTime/3)
    self:setState(self.ejecting)

  -- otherwise, stop the cycle process
  else
    self:stopFireLoop()
    self.cooldownTimer = self.fireTime
  end
end

function Project45GunFire:ejecting()

  -- if gun is cocked per shot
  -- and it's done bursting
  -- pull the bolt (slower animation)
  if self.manualFeed
  and self.burstCounter >= self.burstCount
  or self.reloadTimer >= 0
  then
    -- TODO: animator.setAnimationState("gun", "boltPulling")
    animator.playSound("boltPull")

  -- otherwise, the gun is either semiauto
  -- or not done bursting; we eject (faster animation)
  else
    -- TODO: animator.setAnimationState("gun", "ejecting")
  end


  -- bolt is open(ing)
  animator.setAnimationState("bolt", "open")

  -- if the gun is cocked per shot
  -- and the gun is done bursting,
  -- we for the cock animation to end
  -- otherwise, the gun is semiauto or the gun isn't done bursting:
  -- we wait for the (half) cycle animation to end
  util.wait(
    (self.manualFeed and self.burstCounter >= self.burstCount)
    or self.reloadTimer >= 0
    and
      (self.cockTime/2)
    or
      (self.currentCycleTime/3)
  )
  self:discardCasings()
  animator.setAnimationState("chamber", "empty")  -- empty chamber

  -- if gun has ammo, feed
  if storage.ammo > 0 then
    self:setState(self.feeding)
  
  -- otherwise, reset burst counter (set it to burstcount)
  -- and eject mag if it's supposed to be ejected (like the garand)
  else
    self.burstCounter = self.burstCount
    if self.ejectMagOnEmpty then
      self:ejectMag()
    end
  end
end

function Project45GunFire:feeding()
  if self.manualFeed                              -- if gun is cocked every shot
  and self.burstCounter >= self.burstCount        -- and the gun is done bursting
  or self.reloadTimer >= 0                         -- or the gun was just reloaded/is cocking
  then
    animator.playSound("boltPush")                -- then we were cocking back, and we should cock forward
    -- TODO: animator.setAnimationState("gun", "boltPushing")
  else
    -- TODO: animator.setAnimationState("gun", "feeding")
  end

  animator.setAnimationState("bolt", "closed")
  if storage.ammo > 0 then
    animator.setAnimationState("chamber", "ready")
  end

  -- if this is a slamfire weapon,
  -- we don't wait - the hammer strikes as we feed the round
  if self.slamFire then
    self:setState(self.firing)
    return
  end

  -- otherwise, we wait
  util.wait(
    (self.manualFeed and self.burstCounter >= self.burstCount)
    or self.reloadTimer >= 0
    and
      (self.cockTime/2)
    or
      (self.currentCycleTime/3)
  )

  -- if we aren't done bursting, we continue firing
  if self.burstCounter < self.burstCount
  and self.reloadTimer < 0
  then
    self:setState(self.firing)
  end

  -- prevent triggering
  self.triggered = self.semi or self.reloadTimer >= 0
  
  self.reloadTimer = -1  -- mark end of reload
  activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)
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
  local displayResetTime = self.cockTime/2
  activeItem.setScriptedAnimationParameter("reloadRating", "")
  if storage.ammo < 0 then storage.ammo = 0 end

  -- begin minigame
  while self.reloadTimer <= self.reloadTime do
    activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)
    
    if displayResetTimer <= 0 and storage.ammo < self.maxAmmo then
      activeItem.setScriptedAnimationParameter("reloadRating", "")
      if self.internalMag then
        -- TODO: animator.setAnimationState("magazine", "absent") -- insert mag, hiding it from view
      end
      if self.ejectMagOnReload then
        -- TODO: animator.burstParticleEmitter("magazine") -- throw mag strip
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
      -- TODO: animator.setAnimationState("magazine", "present")

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
  
  -- if there hasn't been any input, just load round
  if storage.ammo <= 0 then
    sumRating = sumRating + 0.5 -- OK: 0.5
    reloads = reloads + 1 -- we did a reload
    animator.playSound("loadRound")
    self:updateAmmo(self.bulletsPerReload)
  end

  -- begin final reload evaluation
  --                     MAX AVERAGE
  -- |  BAD  |  OK  |  GOOD  ||  PERFECT  >
  local finalReloadRating
  local finalScore = sumRating / reloads
  if finalScore > reloads then
    finalReloadRating = PERFECT
  elseif finalScore > reloads * 2/3 then
    finalReloadRating = GOOD
  elseif finalScore > reloads * 1/3 then
    finalReloadRating = OK
  else
    finalReloadRating = BAD
  end
  storage.reloadRating = finalReloadRating
  activeItem.setScriptedAnimationParameter("reloadRating", reloadRatingList[finalReloadRating])
  self.reloadRatingDamage = self.reloadRatingDamageMults[storage.reloadRating]

  animator.playSound("reloadEnd")  -- sound of magazine inserted
  self:setState(self.cocking)
  
end

function Project45GunFire:cocking()

  self.cooldownTimer = self.fireTime

  if animator.animationState("bolt") == "closed"
  or self.reloadTimer >= 0
  then
    self:setState(self.ejecting)
    return
  end

  if animator.animationState("bolt") == "jammed" then
    -- TODO: animator.setAnimationState("gun", "ejected")
    animator.setAnimationState("bolt", "open")
    util.wait(self.cockTime/2)
  end

  if animator.animationState("bolt") == "open" then
    self.burstCounter = self.burstCount
    self.triggered = true
    self.queuedFire = false
    self:setState(self.feeding)
    return
  end

end

function Project45GunFire:unjamming()
  if self.triggered then return end
  self.triggered = true
  self:recoil(true) -- TODO: make me a stance
  -- TODO: animator.setAnimationState("gun", "unjamming") -- should transist back to being jammed
  animator.playSound("unjam")
  self:updateJamAmount(math.random() * -1)
  if storage.jamAmount <= 0 then
    -- animator.playSound("click")
    self.reloadTimer = self.reloadTime
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
    animator.setAnimationState("chamber", "filled")
    self:updateAmmo(-self.ammoPerShot)
    storage.unejectedCasings = math.min(storage.ammo, storage.unejectedCasings + self.ammoPerShot)
    
    -- prevent triggering and firing
    self.triggered = true
    self.queuedFire = false
    self.screenShakeTimer = 0
    self.burstCounter = self.burstCount
    self.chargeTimer = self.resetChargeOnJam and 0 or self.chargeTimer
    self:updateJamAmount(1, true)
    -- self:setState(self.jammed)
    return true
  end
  return false
end

function Project45GunFire:muzzleFlash()
  if not self.beamFiring then
    animator.setSoundPitch("fire", sb.nrand(0.01, 1))
    animator.setSoundVolume("hollow", (1 - storage.ammo/self.maxAmmo) * self.hollowSoundMult)
    animator.playSound("fire")
    animator.playSound("hollow")
  end
  -- TODO: turn on muzzle flash
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
  if self.fireLoopPlaying then
    animator.stopAllSounds("fireLoop")
    animator.stopAllSounds("fireStart")
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
function Project45GunFire:discardCasings()
  if storage.unejectedCasings > 0             -- if there are unejected casings
  and self.burstCounter >= self.burstCount    -- and the gun is done bursting,
  or not self.manualFeed                      -- or if the gun is semiauto
  then                                        -- then we discard casings
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
  self:screenShake()
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
  self.burstCounter = 0
  if self.reloadOnEjectMag then
    self:setState(self.reloading)
  end
  if not self.ejectMagOnEmpty then self:recoil(true) end
  animator.playSound("eject")
  self:updateAmmo(-1, true)
  if self.resetChargeOnEject then
    self.chargeTimer = 0
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

-- UPDATE FUNCTIONS

-- Updates the charge of the gun
-- This is supposed to be called every tick in `Project45GunFire:update()`
function Project45GunFire:updateCharge()

  -- don't bother updating charge stuff if there's no charge in the first place
  if self.chargeTime + self.overchargeTime <= 0
  -- don't bother updating charge if there's no ammo and charge timer is zero anyway
  or self.chargeTimer <= 0 and storage.ammo == 0
  then
    if animator.animationState("charge") == "charging" then
      animator.setAnimationState("charge", "off")
    end
    return
  end

  -- from here on out, either self.chargeTime or self.overchargeTime is nonzero.
  -- It's safe to divide by their sum.

  -- increment/decrement charge timer
  if self:triggering()                                                -- if right click is held down
  and self.reloadTimer < 0                                            -- and gun is not reloading
  and (self.chargeWhenObstructed or not self:muzzleObstructed())      -- and gun can charge while obstructed
  and not (self.semi and self.triggered)                              -- and not already triggered (if semi)
  and storage.ammo >= (self.maintainChargeOnEmpty and 0 or 1) then    -- and the gun still has ammo, then charge
    self.chargeTimer = math.min(self.chargeTime + self.overchargeTime, self.chargeTimer + self.dt)
  else                                                                -- discharge otherwise
    self.chargeTimer = math.max(0, self.chargeTimer - self.dt * self.dischargeTimeMult)
  end
  activeItem.setScriptedAnimationParameter("chargeTimer", self.chargeTimer)

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

  -- update current charge frame (1 to n)
  if self.progressiveCharge then
    self.chargeFrame = math.max(1, math.ceil(self.chargeFrames * (self.chargeTimer / (self.chargeTime + self.overchargeTime))))
    -- progressive charge; charge frame
  else
    --[[
    -- Old code: manually animate shit
    if self.chargeTimer > 0 then
      local advanceFrame = self.chargeAnimationTimer >= self.chargeAnimationTime
      self.chargeFrame = advanceFrame and 1 + (self.chargeFrame % self.chargeFrames) or self.chargeFrame
      self.chargeAnimationTimer = advanceFrame and 0 or self.chargeAnimationTimer + self.dt
    else
      self.chargeFrame = 1
    end
    --]]

    -- New code: use the `charging` layer
    if self.chargeTimer > 0 then
      -- TODO: animator.setAnimationState("charge", "charging")
    else
      -- TODO: animator.setAnimationState("charge", "off")
    end
  end

end

-- Updates the gun's ammo:
-- Sets the gun's stored ammo count 
-- and updates the animation parameter.
-- If not setting the value, the ammo is clamped
-- between 0 and max ammo.
function Project45GunFire:updateAmmo(delta, set)
  storage.ammo = set and delta or clamp(storage.ammo + delta, 0, self.maxAmmo)
  activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
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
  -- this means that the cycle time is expected to be constant
  if not self.cycleTimer then return end

  if self.triggering() and not self.triggered then
    self.cycleTimer = math.min(self.cycleTimer + self.dt, self.cycleTimeMaxTime)
  else
    self.cycleTimer = math.max(0, self.cycleTimer - self.dt)
  end
  
  local cycleTimeProgress = self.cycleTimer / self.cycleTimeMaxTime
  
  self.currentCycleTime = self.cycleTime[1] + self.cycleTimeDiff * cycleTimeProgress
  self.chargeAnimationTime = self.currentCycleTime/3
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
    -- TODO: turn off muzzle flash
  end
end

-- updates the weapon's stance
-- interpolates the weapon's stance to the stance set via self.weapon:setStance()
function Project45GunFire:updateStance()

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
    
    -- initialize projectile stack
    -- this stack is used by the hitscan functions and the animator
    -- to animate hitscan trails.
    self.projectileStack = {}

    if self.laser then
      activeItem.setScriptedAnimationParameter("laserColor", self.laser.color)
      activeItem.setScriptedAnimationParameter("laserWidth", self.laser.width)
    end
  end

  local muzzleFlashColor = config.getParameter("muzzleFlashColor", {255, 255, 200})
  self.updateProjectileStack = function() end
  if self.projectileKind == "hitscan" then
    self.fireProjectile = hitscanLib.fireHitscan
    self.updateProjectileStack = hitscanLib.updateProjectileStack
    self.hitscanParameters.hitscanColor = muzzleFlashColor
  elseif self.projectileKind == "beam" then
    self.firing = hitscanLib.fireBeam
    self.updateProjectileStack = hitscanLib.updateProjectileStack
    self.beamParameters.beamColor = muzzleFlashColor
    activeItem.setScriptedAnimationParameter("beamColor", muzzleFlashColor)
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
  return diceroll(self.critChance) and 1 or self.critMult
end

-- Calculates the damage per shot of the weapon.
function Project45GunFire:damagePerShot(isHitscan)
  return self.baseDamage
  * activeItem.ownerPowerMultiplier()
  * self.chargeDamage -- up to 2x at full overcharge
  * self.reloadRatingDamage -- as low as 0.8 (bad), as high as 1.5 (perfect)
  * self:crit() -- this way, rounds deal crit damage individually
  / self.projectileCount
end

-- Returns whether the left click is held
function Project45GunFire:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
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

-- HELPER FUNCTIONS

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