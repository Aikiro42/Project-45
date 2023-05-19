require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"
require "/items/active/weapons/ranged/gunfire.lua"
require "/items/active/weapons/ranged/abilities/synthetikmechanics/synthetikmechanics.lua"

Project45UnderbarrelGun = GunFire:new()

local READY, FILLED, EMPTY = 0, 1, 2

function Project45UnderbarrelGun:init()
    self.aimProgress = 0
    self.firing = false
    self.debugTimer = 0
    self.muzzleFlashTimer = 0
    self.cooldownTimer = self.fireTime
    storage.underbarrelGunState = storage.underbarrelGunState or config.getParameter("currentUnderbarrelGunState", EMPTY)
    storage.underbarrelGunAmmo = storage.underbarrelGunAmmo or config.getParameter("currentUnderbarrelGunAmmo", 0)

    activeItem.setScriptedAnimationParameter("underbarrelGunAmmoIndicatorOffset", self.indicatorOffset)
    activeItem.setScriptedAnimationParameter("underbarrelGunAmmo", storage.underbarrelGunAmmo)
    activeItem.setScriptedAnimationParameter("underbarrelGunState", storage.underbarrelGunState)

end

function Project45UnderbarrelGun:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

    if self.muzzleFlashTimer == 0 then
        animator.setLightActive("altMuzzle", false)
    else
        self.muzzleFlashTimer = math.max(0, self.muzzleFlashTimer - self.dt)
    end

    if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
        self.firing = false
    end

    if self.fireMode == "alt"
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not self.firing then

        if (shiftHeld and storage.underbarrelGunAmmo < self.maxAmmo)
        or storage.underbarrelGunAmmo == 0 then
            self:setState(self.loadRound)
        
        elseif storage.underbarrelGunState == EMPTY then
            if animator.animationState("underbarrelgun") == "closed" then
                self:setState(self.open)
            else
                self:setState(self.close)
            end
        elseif storage.underbarrelGunState == READY
        and not world.lineTileCollision(mcontroller.position(), self:firePosition())
        then
            self:setState(self.fire)
        
        elseif storage.underbarrelGunState == FILLED then
            self:setState(self.open)

        end
        

        self.cooldownTimer = self.fireTime
        self.firing = true

    end

end

function Project45UnderbarrelGun:fire()
    self:fireProjectile()
    self:updateAmmo(-1)
    self:updateGunState(FILLED)
    self:muzzleFlash()
    self:recoil()
end

function Project45UnderbarrelGun:loadRound()

    if storage.underbarrelGunAmmo == self.maxAmmo
    or status.resourceLocked("energy")
    then return end

    local reloadRotation = 15

    local oldWeaponOffset = self.weapon.weaponOffset
    local oldRelativeWeaponRotation = self.weapon.relativeWeaponRotation
    local oldRelativeArmRotation = self.weapon.relativeArmRotation
    local oldFrontArmFrame = self.weapon.stance.frontArmFrame
    local stepTime = self.reloadTime/4

    --[[



    local progress = 0
    util.wait(stepTime, function()
        storage.aimProgress = 0
        local from = oldWeaponOffset
        local to = self.reloadWeaponOffset
        self.weapon.weaponOffset = {interp.sin(progress, from[1], to[1]), interp.sin(progress, from[2], to[2])}
        
        self.weapon.relativeWeaponRotation = interp.sin(progress, oldRelativeWeaponRotation, oldRelativeWeaponRotation + util.toRadians(15))
        self.weapon.relativeArmRotation = interp.sin(progress, oldRelativeArmRotation, oldRelativeArmRotation - util.toRadians(15))
        -- self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(0.1)
        progress = math.min(1.0, progress + (self.dt / stepTime))
    end)

    --]]

    while true do


        status.overConsumeResource("energy", status.resourceMax("energy") * self.reloadCostPercent)
        animator.playSound("altInsertRound")
        self:updateAmmo(self.ammoPerReload or 1)

        self.weapon.weaponOffset = self.reloadWeaponOffset
        self.weapon.relativeWeaponRotation = oldRelativeWeaponRotation + util.toRadians(reloadRotation)
        self.weapon.relativeArmRotation = oldRelativeArmRotation - util.toRadians(reloadRotation)
        self.weapon.stance.frontArmFrame = "swim.3"
        util.wait(stepTime, function() storage.aimProgress = 0 end)

        
        coroutine.yield()

    if not (self.firing or self.fireMode == "alt")
        or storage.underbarrelGunAmmo == self.maxAmmo
        or status.resourceLocked("energy") then break
    else
        self.weapon.stance.frontArmFrame = "idle.1"
        util.wait(stepTime, function() storage.aimProgress = 0 end)
    end
    
    end

    progress = 0
    util.wait(stepTime, function()
        storage.aimProgress = 0
        local from = self.reloadWeaponOffset
        local to = oldWeaponOffset
        self.weapon.weaponOffset = {interp.sin(progress, from[1], to[1]), interp.sin(progress, from[2], to[2])}
        
        self.weapon.relativeWeaponRotation = interp.sin(progress, oldRelativeWeaponRotation + util.toRadians(15), oldRelativeWeaponRotation)
        self.weapon.relativeArmRotation = interp.sin(progress, oldRelativeArmRotation - util.toRadians(15), oldRelativeArmRotation)
        -- self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(0.1)
        progress = math.min(1.0, progress + (self.dt / stepTime))
    end)


    --[[
        progress = 0
        util.wait(stepTime, function()
            self.weapon.relativeWeaponRotation = interp.sin(progress, oldOldRelativeWeaponRotation + util.toRadians(15), oldOldRelativeWeaponRotation)
            self.weapon.relativeArmRotation = interp.sin(progress, oldOldRelativeArmRotation - util.toRadians(15), oldOldRelativeArmRotation)
            -- self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(0.1)
            progress = math.min(1.0, progress + (self.dt / stepTime))
        end)
        -- coroutine.yield()
    -- end
    --]]
    
    --[[
    progress = 0
    util.wait(stepTime, function()
        storage.aimProgress = 0
        local from = self.reloadWeaponOffset
        local to = oldWeaponOffset
        self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.sin(progress, from[2], to[2])}
        self.weapon.relativeWeaponRotation = interp.sin(progress, oldRelativeWeaponRotation + util.toRadians(15), oldRelativeWeaponRotation)
        self.weapon.relativeArmRotation = interp.sin(progress, oldRelativeArmRotation - util.toRadians(15), oldRelativeWeaponRotation)
        -- self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(0.1)
        if progress > 0.5 then
            self.weapon.stance.frontArmFrame = oldFrontArmFrame
        end
        progress = math.min(1.0, progress + (self.dt / stepTime))
    end)
    --]]

    
    self.weapon.weaponOffset = oldWeaponOffset
    self.weapon.relativeWeaponRotation = oldRelativeWeaponRotation
    self.weapon.relativeArmRotation = oldRelativeWeaponRotation
    self.weapon.stance.frontArmFrame = oldFrontArmFrame

    -- 4. move weapon forward
    --[[
    local progress = 0
    util.wait(self.reloadTime, function()
        local from = self.reloadWeaponOffset
        local to = oldWeaponOffset
        self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

        progress = math.min(1.0, progress + (self.dt / self.reloadTime))
    end)
    --]]


end

function Project45UnderbarrelGun:open()

    if animator.animationState("underbarrelgun") == "open" then return end

    animator.setAnimationState("underbarrelgun", "open")
    animator.playSound("open")
    
    if storage.underbarrelGunState == FILLED then
        animator.burstParticleEmitter("altEjectionPort", true)
    end
    
    self:updateGunState(EMPTY)
    
    self:recoil(true)

end

function Project45UnderbarrelGun:close()
    if animator.animationState("underbarrelgun") == "closed" then return end

    if storage.underbarrelGunAmmo > 0 then
        self:updateGunState(READY)
    end
    
    animator.setAnimationState("underbarrelgun", "closed")
    animator.playSound("load")
    
    
    self:recoil(true)
end

function Project45UnderbarrelGun:recoil(down)
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(5) * (down and -1 or 1)
    self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(5) * (down and -1 or 1)
    storage.aimProgress = 0
end

function Project45UnderbarrelGun:aim()  
    -- self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())    
    self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeWeaponRotation), self.weapon.stance.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeArmRotation), self.weapon.stance.armRotation))
end

function Project45UnderbarrelGun:updateAmmo(ammoDelta)
    
    storage.underbarrelGunAmmo = clamp(0, self.maxAmmo, storage.underbarrelGunAmmo + ammoDelta)
    activeItem.setScriptedAnimationParameter("underbarrelGunAmmo", storage.underbarrelGunAmmo)
    activeItem.setInstanceValue("currentUnderbarrelGunAmmo", storage.underbarrelGunAmmo)

end

function Project45UnderbarrelGun:updateGunState(newState)
    
    storage.underbarrelGunState = newState
    activeItem.setScriptedAnimationParameter("underbarrelGunState", newState)
    activeItem.setInstanceValue("currentUnderbarrelGunState", newState)

end

function Project45UnderbarrelGun:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
    local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
    params.power = self.projectileParameters.power or 1
    params.powerMultiplier = activeItem.ownerPowerMultiplier()
    params.speed = util.randomInRange(params.speed)
  
    if not projectileType then
      projectileType = self.projectileType
    end
    if type(projectileType) == "table" then
      projectileType = projectileType[math.random(#projectileType)]
    end
  
    local projectileId = 0
    for i = 1, (projectileCount or self.projectileCount) do
      if params.timeToLive then
        params.timeToLive = util.randomInRange(params.timeToLive)
      end
  
      projectileId = world.spawnProjectile(
          projectileType,
          firePosition or self:firePosition(),
          activeItem.ownerEntityId(),
          self:aimVector(inaccuracy or self.inaccuracy),
          false,
          params
        )
    end
    return projectileId
end

function Project45UnderbarrelGun:muzzleFlash()
    if self.useParticleEmitter == nil or self.useParticleEmitter then
      animator.burstParticleEmitter("altMuzzle", true)
    end
    animator.playSound("altFire")
    animator.setLightActive("altMuzzle", true)
    self.muzzleFlashTimer = 0.025
end

function Project45UnderbarrelGun:firePosition()
    return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint(self.firePositionPart, "firePosition")))
    -- return activeItem.handPosition(animator.partPoint(self.firePositionPart, "firePosition"))
end

function Project45UnderbarrelGun:aimVector(spread)
    local launcherMuzzle = animator.partPoint(self.firePositionPart, "firePosition")
    local firePos = vec2.add(mcontroller.position(), activeItem.handPosition(launcherMuzzle))
    local basePos =  vec2.add(mcontroller.position(), activeItem.handPosition({launcherMuzzle[1]-1, launcherMuzzle[2]}))
    world.debugPoint(basePos, "green")
    world.debugPoint(firePos, "red")
    local aimVector = vec2.norm(world.distance(firePos, basePos))
    aimVector = vec2.rotate(aimVector, sb.nrand((spread or 0), 0))
    return aimVector
end

function Project45UnderbarrelGun:uninit()
end

function Project45UnderbarrelGun:screenShake(amount, shakeTime, random)
    SynthetikMechanics.screenShake(self, amount, shakeTime, random)
end

function clamp(lo, hi, val)
    if val < lo then
        return lo
    elseif val > hi then
        return hi
    else
        return val
    end
end