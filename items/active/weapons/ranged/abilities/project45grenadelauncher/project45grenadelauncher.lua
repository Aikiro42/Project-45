require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"
require "/items/active/weapons/ranged/gunfire.lua"
require "/items/active/weapons/ranged/abilities/synthetikmechanics/synthetikmechanics.lua"

Project45GrenadeLauncher = GunFire:new()

local READY, EMPTY, OPEN = 0, 1, 2

function Project45GrenadeLauncher:init()
    self.aimProgress = 0
    self.firing = false
    self.debugTimer = 0
    self.muzzleFlashTimer = 0
    self.cooldownTimer = self.fireTime
    storage.grenadeLauncherState = storage.grenadeLauncherState or EMPTY
    self:setGrenadeLauncherState(storage.grenadeLauncherState)
    activeItem.setScriptedAnimationParameter("grenadeIndicatorOffset", self.indicatorOffset)
    activeItem.setScriptedAnimationParameter("trajectoryIndicatorColor", self.trajectoryIndicatorColor)
    self.projectileParameters.speed = self.projectileParameters.speed or root.projectileConfig(self.projectileType).speed or 50
    activeItem.setScriptedAnimationParameter("altProjectileSpeed", self.projectileParameters.speed)
end

function Project45GrenadeLauncher:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    activeItem.setScriptedAnimationParameter("altMuzzlePos", self:firePosition())
    activeItem.setScriptedAnimationParameter("altAimAngle", vec2.angle(self:aimVector()))
    
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
    and self.cooldownTimer == 0
    and not self.weapon.currentAbility
    and not self.firing then

        if storage.grenadeLauncherState == READY
        and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
            self:setState(self.charging)

        elseif storage.grenadeLauncherState == EMPTY then
            self:setState(self.eject)

        elseif storage.grenadeLauncherState == OPEN then
            if not status.resourceLocked("energy") and status.overConsumeResource("energy", status.resourceMax("energy") * self.energyUsagePercent) then
                self:setState(self.load)
            end

        end
        
        self.cooldownTimer = self.fireTime
        self.firing = true

    end

end

function Project45GrenadeLauncher:charging()
    local chargeTimer = self.chargeTime
    local flashTime = 0.03
    local flashTimer = 0
    local flashTimeStep = self.dt
    animator.playSound("charge", -1)
    while self.fireMode == "alt" do
        
        chargeTimer = math.max(0, chargeTimer - self.dt)
        flashTimer = flashTimer + flashTimeStep

        if flashTimeStep > 0 and flashTimer >= flashTime then
            activeItem.setScriptedAnimationParameter("grenadeLauncherChargeWarning", false)
            flashTimeStep = -self.dt
        elseif flashTimeStep < 0 and flashTimer <= 0 then
            activeItem.setScriptedAnimationParameter("grenadeLauncherChargeWarning", true)
            flashTimeStep = self.dt
        end

        if chargeTimer <= 0 then
            animator.stopAllSounds("charge")
            self:setState(self.fire)
            break
        end

        coroutine.yield()
    end
    activeItem.setScriptedAnimationParameter("grenadeLauncherChargeWarning", false)
    animator.stopAllSounds("charge")
end


function Project45GrenadeLauncher:fire()
    activeItem.setScriptedAnimationParameter("grenadeLauncherChargeWarning", false)
    self:fireProjectile()
    self:setGrenadeLauncherState(EMPTY)
    self:muzzleFlash()
    self:recoil()
end

function Project45GrenadeLauncher:eject()
    animator.setAnimationState("grenadelauncher", "open")
    animator.playSound("open")
    animator.burstParticleEmitter("altEjectionPort", true)
    self:setGrenadeLauncherState(OPEN)
    self:recoil(true)
end

function Project45GrenadeLauncher:load()
    animator.setAnimationState("grenadelauncher", "closed")
    animator.playSound("load")
    self:setGrenadeLauncherState(READY)
    self:recoil(true)
end

function Project45GrenadeLauncher:recoil(down)

    local mult = down and -1 or 1
    self.weapon.relativeWeaponRotation = math.min(self.weapon.relativeWeaponRotation, util.toRadians(15 / 2)) + util.toRadians(7.5 * mult)
    self.weapon.relativeArmRotation = math.min(self.weapon.relativeArmRotation, util.toRadians(15 / 2)) + util.toRadians(7.5 * mult)
    self.weapon.weaponOffset = {-0.125, 0}
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(sb.nrand(1, 0) * 7.5)
    storage.stanceProgress = 0  
    storage.aimProgress = 0
end

function Project45GrenadeLauncher:aim()  
    -- self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())    
    self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeWeaponRotation), self.weapon.stance.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeArmRotation), self.weapon.stance.armRotation))
end



function Project45GrenadeLauncher:setGrenadeLauncherState(launcherState)
    storage.grenadeLauncherState = launcherState
    activeItem.setScriptedAnimationParameter("grenadeLauncherState", launcherState)
    -- activeItem.setInstanceValue("currentGrenadeLauncherState", launcherState)
end

function Project45GrenadeLauncher:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
    local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
    -- deals the player's power stat as damage times the threat level
    params.power = 100
    params.powerMultiplier = activeItem.ownerPowerMultiplier() * world.threatLevel()
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

function Project45GrenadeLauncher:muzzleFlash()
    if self.useParticleEmitter == nil or self.useParticleEmitter then
      animator.burstParticleEmitter("altMuzzle", true)
    end
    animator.playSound("altFire")
    animator.setLightActive("altMuzzle", true)
    self.muzzleFlashTimer = 0.025
end

function Project45GrenadeLauncher:firePosition()
    return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint(self.firePositionPart, "firePosition")))
    -- return activeItem.handPosition(animator.partPoint(self.firePositionPart, "firePosition"))
end

function Project45GrenadeLauncher:aimVector(spread)
    local launcherMuzzle = animator.partPoint(self.firePositionPart, "firePosition")
    local firePos = vec2.add(mcontroller.position(), activeItem.handPosition(launcherMuzzle))
    local basePos =  vec2.add(mcontroller.position(), activeItem.handPosition({launcherMuzzle[1]-1, launcherMuzzle[2]}))
    world.debugPoint(basePos, "green")
    world.debugPoint(firePos, "red")
    local aimVector = vec2.norm(world.distance(firePos, basePos))
    aimVector = vec2.rotate(aimVector, sb.nrand((spread or 0), 0))
    return aimVector
end

function Project45GrenadeLauncher:uninit()
end

function Project45GrenadeLauncher:screenShake(amount, shakeTime, random)
    SynthetikMechanics.screenShake(self, amount, shakeTime, random)
end
