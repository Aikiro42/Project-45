require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"
require "/items/active/weapons/ranged/gunfire.lua"
require "/items/active/weapons/ranged/abilities/synthetikmechanics/synthetikmechanics.lua"

Project45GrenadeLauncher = GunFire:new()

local READY, EMPTY, OPEN = 0, 1, 2

function Project45GrenadeLauncher:init()
    self.aimProgress = 0
    self.firing = false
    storage.grenadeLauncherState = storage.grenadeLauncherState or EMPTY
end

function Project45GrenadeLauncher:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)
        
    if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
        self.firing = false
    end
    
    if self.fireMode == "alt" and not self.weapon.currentAbility and not self.firing then

        if storage.grenadeLauncherState == READY
        and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
            self:setState(self.fire)

        elseif storage.grenadeLauncherState == EMPTY then
            self:setState(self.eject)

        elseif storage.grenadeLauncherState == OPEN then
            if not status.resourceLocked("energy") and status.overConsumeResource("energy", status.resourceMax("energy") * self.energyUsagePercent) then
                self:setState(self.load)
            end

        end

        self.firing = true

    end

end

function Project45GrenadeLauncher:fire()
    self:fireProjectile()
    storage.grenadeLauncherState = EMPTY
    self:muzzleFlash()
end

function Project45GrenadeLauncher:eject()
    animator.setAnimationState("grenadelauncher", "open")
    animator.playSound("open")
    storage.grenadeLauncherState = OPEN
end

function Project45GrenadeLauncher:load()
    animator.setAnimationState("grenadelauncher", "closed")
    animator.playSound("load")
    storage.grenadeLauncherState = READY
end

function Project45GrenadeLauncher:recoil(down)
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(5) * (down and -1 or 1)
    self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(5) * (down and -1 or 1)
    self.aimProgress = 0
end

function Project45GrenadeLauncher:aim()  
    -- self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())    
    self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeWeaponRotation), self.weapon.stance.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.sin(self.aimProgress, math.deg(self.weapon.relativeArmRotation), self.weapon.stance.armRotation))
end

function Project45GrenadeLauncher:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
    local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
    params.power = 100
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

function Project45GrenadeLauncher:muzzleFlash()
    if self.useParticleEmitter == nil or self.useParticleEmitter then
      animator.burstParticleEmitter("altMuzzleFlash", true)
    end
    animator.playSound("altFire")
end

function Project45GrenadeLauncher:firePosition()
    return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint(self.firePositionPart, "firePosition")))
end

function Project45GrenadeLauncher:uninit()
end

function Project45GrenadeLauncher:screenShake(amount, shakeTime, random)
    SynthetikMechanics.screenShake(self, amount, shakeTime, random)
end
