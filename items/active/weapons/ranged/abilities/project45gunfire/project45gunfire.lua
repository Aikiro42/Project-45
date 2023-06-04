require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

Project45GunFire = WeaponAbility:new()

function Project45GunFire:init()

  -- evaluate whether the user is an NPC
  self.usedByNPC = world.entityType(activeItem.ownerEntityId())

  self.fireTime = 1 / self.fireRate  -- set fire rate
  
  -- separate cock time and reload time
  self.cockTime = self.reloadTime * 0.2
  self.reloadTime = self.reloadTime * 0.8
  self.reloadTimer = -1

  -- don't bother calculating if charge is not progressive
  if not self.progressiveCharge then
    self.chargeAnimationTime = self.cycleTime/3
    self.chargeAnimationTimer = 0
  end

  self.chargeFrame = 1
  animator.setGlobalTag("chargeFrame", self.chargeFrame)

  self.chargeDamage = 1

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

  -- let recoverTime be a table
  if type(self.recoverTime) ~= "table" then
    self.recoverTime = {
      mobile = self.recoverTime*4,  -- quadruple recover time while running
      walking = self.recoverTime*2,  -- double recover time while walking
      stationary = self.recoverTime, -- standard recover time while standing
      crouching = self.recoverTime/2 -- halfed recover time while crouching
    }
  end
  self.currentRecoverTime = self.recoverTime.mobile

  -- validate quick reload timeframe; perfect reload must be within bounds of good reload
  if self.quickReloadTimeframe[4] < self.quickReloadTimeframe[1] then
    -- swap if latter is bigger than former
    local temp = self.quickReloadTimeframe[1]
    self.quickReloadTimeframe[1] = self.quickReloadTimeframe[4]
    self.quickReloadTimeframe[4] = temp
  end
  self.quickReloadTimeframe[2] = math.max(self.quickReloadTimeframe[1], self.quickReloadTimeframe[2])
  self.quickReloadTimeframe[3] = math.min(self.quickReloadTimeframe[3], self.quickReloadTimeframe[4])

  -- grab stored data
  storage.ammo = storage.ammo or config.getParameter("currentAmmo", self.maxAmmo)
  storage.stanceProgress = 0 -- stance progres is stored in storage so that other weapons may recoil the gun
  storage.unejectedCasings = storage.unejectedCasings or 0

  self.jamAmount = config.getParameter("currentJamAmount", 0)

  -- initialize timers
  self.chargeTimer = 0
  self.cooldownTimer = self.fireTime

  -- initialize animation stuff
  
  activeItem.setScriptedAnimationParameter("reloadTimer", -1)
  activeItem.setScriptedAnimationParameter("chargeTimer", 0)
  activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
  
  activeItem.setScriptedAnimationParameter("reloadTime", self.reloadTime)
  activeItem.setScriptedAnimationParameter("quickReloadTimeframe", self.quickReloadTimeframe)

  activeItem.setScriptedAnimationParameter("chargeTime", self.chargeTime)
  activeItem.setScriptedAnimationParameter("overchargeTime", self.overchargeTime)

  
  self.stances = {}
  self.stances.aimStance = {
    weaponRotation = 0,
    armRotation = 0,
    twoHanded = config.getParameter("twoHanded", false),
    allowRotate = true,
    allowFlip = true
  }

  self.weapon:setStance(self.stances.aimStance)
  self:recoil(true)

end

function Project45GunFire:update(dt, fireMode, shiftHeld)

  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  self:updateCharge()
  self:updateStance()
  
  -- accuracy settings
  local movementState = self:getMovementState()
  self.currentInaccuracy = self.inaccuracy[movementState]
  self.currentRecoverTime = self.recoverTime[movementState]
  -- activeItem.setCursor("/cursors/project45reticle" .. x .. ".cursor")
  
  if self:triggering()
  and not self.triggered
  and not self.weapon.currentAbility
  and self.cooldownTimer == 0
  then

    if storage.ammo > 0 then

      if animator.animationState("chamber") == "ready" then
        if self.chargeTimer >= self.chargeTime then
          self:setState(self.firing)
        end
      elseif animator.animationState("chamber") == "filled" then
        self:recoil(true)
        self:setState(self.ejecting)
      else
        self:setState(self.cocking)
      end

      self.triggered = self.semi or storage.ammo == 0

    else
      
      if storage.ammo == 0 then
        self:ejectMag()
      else
        self:setState(self.reloading)
      end
      self.triggered = true

    end

      
    self.cooldownTimer = self.fireTime

  elseif not self:triggering() then
    self.triggered = false
  end

end

function Project45GunFire:uninit()
  activeItem.setInstanceValue("currentAmmo", storage.ammo)
  activeItem.setInstanceValue("currentJamAmount", storage.jamAmount)
  activeItem.setInstanceValue("currentReloadRating", storage.reloadRating)
end

-- STATE FUNCTIONS

function Project45GunFire:jammed()
end

function Project45GunFire:firing()
  self:applyInaccuracy()
  self:fireProjectile()
  animator.playSound("fire")
  animator.setAnimationState("gun", "firing")
  if self.resetChargeOnFire then self.chargeTimer = 0 end
  self:recoil()

  -- add unejected casings
  self:updateAmmo(-self.ammoPerShot)
  storage.unejectedCasings = storage.unejectedCasings + self.ammoPerShot
  animator.setAnimationState("chamber", "filled")
  
  if not self.manualFeed then
    util.wait(self.cycleTime/3)
    self:setState(self.ejecting)
  end
end

function Project45GunFire:ejecting()
  animator.setAnimationState("gun", "ejecting")
  
  -- eject casings
  self:discardCasings()

  animator.setAnimationState("chamber", "empty")
  util.wait(self.cycleTime/3)
  if storage.ammo > 0 then
    self:setState(self.feeding)
  elseif self.ejectMagOnEmpty then
    self:ejectMag()
  end
end

function Project45GunFire:feeding()
  animator.setAnimationState("gun", "feeding")
  animator.setAnimationState("chamber", "ready")
  util.wait(self.cycleTime/3)
end

function Project45GunFire:reloading()
  
  self.reloadTimer = 0 -- mark begin of reload

  animator.playSound("getmag")

  self.triggered = true  -- prevent accidentally reloading instantly
  
  local finalReloadRating = ""
  
  -- general reload rating calculation
  -- reload rating is calculated as the average across reloads
  local sumRating = 0
  local reloads = 0
  local displayResetTimer = 0
  local displayResetTime = 0.5 -- TODO: make me a setting
  activeItem.setScriptedAnimationParameter("reloadRating", "")

  -- begin minigame
  while self.reloadTimer <= self.reloadTime do
    activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)
    
    if displayResetTimer <= 0 then
      activeItem.setScriptedAnimationParameter("reloadRating", "")
      displayResetTimer = displayResetTime
    else
      displayResetTimer = displayResetTimer - self.dt
    end
    
    -- process left click
    -- do not process left click if (full) bad reload has been attempted
    if self:triggering() and not self.triggered and storage.ammo < self.maxAmmo then
      
      -- count reload
      reloads = reloads + 1
      
      -- get this reload's reloadRating
      local reloadRating = self:reloadRating()
      activeItem.setScriptedAnimationParameter("reloadRating", reloadRating)
      
      -- add rating to sum
      -- BAD: 0
      -- GOOD: 1
      -- PERFECT: 2
      if reloadRating == "GOOD" then
        sumRating = sumRating + 1
      elseif reloadRating == "PERFECT" then
        sumRating = sumRating + 2
      end
      
      self.triggered = true
      
      -- update ammo
      animator.playSound("loadRound")
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
  
  -- if there hasn't been any input, load round
  if storage.ammo < 0 then
    sumRating = sumRating + 0.5
    animator.playSound("loadRound")
    self:updateAmmo(self.bulletsPerReload)
  end

  -- begin final reload evaluation
  local finalScore = sumRating / reloads
  if finalScore > 1 then
    finalReloadRating = "PERFECT"
  elseif finalScore > 2/3 then
    finalReloadRating = "GOOD"
  elseif finalScore > 1/3 then
    finalReloadRating = "OK"
  else
    finalReloadRating = "BAD"
  end
  activeItem.setScriptedAnimationParameter("reloadRating", finalReloadRating)

  animator.playSound("reload")
  self:setState(self.cocking)
  
end

function Project45GunFire:cocking()
  
  -- if idle, eject
  if animator.animationState("gun") == "idle" then
    animator.setAnimationState("gun", "ejecting")
    self:discardCasings()
    animator.setAnimationState("chamber", "empty")
  end
  util.wait(self.cycleTime/3)

  -- if ejecting/ejected, feed
  if animator.animationState("gun") == "ejected" or animator.animationState("gun") == "ejecting" then
    animator.setAnimationState("gun", "feeding")
    if storage.ammo > 0 then
      animator.setAnimationState("chamber", "ready")
    end
    util.wait(self.cycleTime/3)
  end

  self.cooldownTimer = self.fireTime
  util.wait(self.fireTime)
  self.reloadTimer = -1  -- mark end of reload
  activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)

end

-- ACTION FUNCTIONS

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

function Project45GunFire:discardCasings()
  if storage.unejectedCasings > 0 then
    animator.setParticleEmitterBurstCount("ejectionPort", storage.unejectedCasings)
    animator.burstParticleEmitter("ejectionPort")
    storage.unejectedCasings = 0
  end
end

function Project45GunFire:applyInaccuracy()
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + sb.nrand(self.currentInaccuracy, 0)
  storage.stanceProgress = 0
end

function Project45GunFire:recoil(down, mult)
  local mult = mult or self.recoilMult
  mult = down and -mult or mult
  self.weapon.relativeWeaponRotation = math.min(self.weapon.relativeWeaponRotation, util.toRadians(self.maxRecoilDeg / 2)) + util.toRadians(self.recoilAmount * mult)
  self.weapon.relativeArmRotation = math.min(self.weapon.relativeArmRotation, util.toRadians(self.maxRecoilDeg / 2)) + util.toRadians(self.recoilAmount * mult)
  self.weapon.weaponOffset = {-0.1, 0}
  storage.stanceProgress = 0
end

function Project45GunFire:ejectMag()
  self:recoil(true)
  animator.playSound("eject")
  animator.setAnimationState("mag", "absent")
  self:updateAmmo(-1, true)
  if self.reloadOnEjectMag then
    self:setState(self.reloading)
  end
end

-- UPDATE FUNCTIONS

-- Updates the charge of the gun
-- This is supposed to be called every tick in `Project45GunFire:update()`
function Project45GunFire:updateCharge()

  -- don't bother updating charge stuff if there's no charge in the first place
  if self.chargeTime + self.overchargeTime <= 0 then return end

  -- from here on out, either self.chargeTime or self.overchargeTime is nonzero.
  -- It's safe to divide by their sum.

  -- increment/decrement charge timer
  if self:triggering()
  and self.reloadTimer < 0
  and storage.ammo >= 0 then
    -- charge up if triggered
    self.chargeTimer = math.min(self.chargeTime + self.overchargeTime, self.chargeTimer + self.dt)
  else
    -- charge down otherwise
    self.chargeTimer = math.max(0, self.chargeTimer - self.dt * self.dischargeTimeMult)
  end
  activeItem.setScriptedAnimationParameter("chargeTimer", self.chargeTimer)

  -- update variables dependent on the charge timer:

  -- update charge damage multiplier
  if self.overchargeTime > 0 then
    self.chargeDamage = 1 + self.chargeTime - self.chargeTimer / self.overchargeTime
  end

  -- update current charge frame (1 to n)
  if self.progressiveCharge then
    self.chargeFrame = math.max(1, math.ceil(self.chargeFrames * (self.chargeTimer / (self.chargeTime + self.overchargeTime))))
    -- progressive charge; charge frame
  else
    if self.chargeTimer > 0 then
      local advanceFrame = self.chargeAnimationTimer >= self.chargeAnimationTime
      self.chargeFrame = advanceFrame and 1 + (self.chargeFrame % self.chargeFrames) or self.chargeFrame
      self.chargeAnimationTimer = advanceFrame and 0 or self.chargeAnimationTimer + self.dt
    else
      self.chargeFrame = 1
    end
  end

  animator.setGlobalTag("chargeFrame", self.chargeFrame)

end

-- Updates the gun's ammo:
-- Sets the gun's stored ammo count 
-- and updates the animation parameter.
function Project45GunFire:updateAmmo(delta, set)
  storage.ammo = delta > 0 and storage.ammo < 0 and 0 or storage.ammo
  storage.ammo = math.min(set and delta or storage.ammo + delta, self.maxAmmo)
  activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
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
    return "PERFECT"
  elseif self.reloadTime * self.quickReloadTimeframe[1] <= self.reloadTimer and self.reloadTimer <= self.reloadTime * self.quickReloadTimeframe[4] then
    return "GOOD"
  else
    return "BAD"
  end
end

-- Returns the critical multiplier.
-- Typically called when the weapon is about to deal damage.
function Project45GunFire:crit()
  return diceroll(self.critChance) and 1 or self.critMult
end

-- Calculates the damage per shot of the weapon.
function Project45GunFire:damagePerShot(isHitscan)
  
  local reloadDamageMults = {
    BAD = 1,
    OK = 1,
    GOOD = 1.25,
    PERFECT = 1.5
  }

  return self.baseDamage / self.projectileCount
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

-- HELPER FUNCTIONS

function diceroll(chance)
  return math.random <= chance
end