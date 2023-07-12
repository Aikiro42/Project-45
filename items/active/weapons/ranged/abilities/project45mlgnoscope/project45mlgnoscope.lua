require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"
require "/items/active/weapons/ranged/gunfire.lua"

Project45MLGNoScope = GunFire:new()

function Project45MLGNoScope:init()
    self.cooldownTimer = 0
    self.logTimer = 0
    self.fireTime = 0.1
    self.noscopeTime = (storage.primaryChargeTime or 0) + self.noscopeTime
    self.noscopeTimer = 0
    self.rotating = false
    self.oppositeDirectionDetectionThreshold = self.oppositeDirectionDetectionThreshold or 10
    self.bonusDamage = false
    activeItem.setScriptedAnimationParameter("altTotalAngle", nil)
end

function Project45MLGNoScope:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    self.noscopeTimer = math.max(0, self.noscopeTimer - self.dt)

    if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
        self.firing = false
    end

    if self.noscopeTimer <= 0 and not self.rotating then
        animator.stopAllSounds("noscopeProgressLoop")
        activeItem.setScriptedAnimationParameter("altTotalAngle", nil)
    end

    if self.fireMode == "alt"
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not self.firing then

        self:setState(self.threesixty)

        self.cooldownTimer = self.fireTime
        self.firing = true

    end


    --[[
    if self.logTimer > 0 then
        -- sb.logInfo(sb.printJson(self.bonusDamage))
        self.logTimer = self.logTimer - self.dt
    end
    --]]

end

function Project45MLGNoScope:getAimAngle()
    local a = activeItem.aimAngle(0, activeItem.ownerAimPosition())
    a = math.floor(util.toDegrees(a))
    if a < 0 then
        a = a + 360
    end
    return a
end

function cross(v1, v2)
    return (v1[1] * v2[2]) - (v1[2] * v2[1])
end

function totalAngle(v1, v2)
    local cos = vec2.dot(v1, v2)
    local sin = cross(v1, v2)
    local theta = util.toDegrees(math.atan(sin, cos))
    if theta < 0 then theta = theta + 360 end
    return theta
end

function Project45MLGNoScope:threesixty()
    
    animator.stopAllSounds("noscopeProgressLoop")
    activeItem.setScriptedAnimationParameter("altTotalAngle", nil)
    animator.playSound("noscopeProgressLoop", -1)

    local initialVector = vec2.rotate({1, 0}, activeItem.aimAngle(0, activeItem.ownerAimPosition()))
    
    local oldAngle = 0
    local rotationDirection = 0
    local totalRotation = 0
    local noscope = false

    self.rotating = true
    self.bonusDamage = world.gravity(mcontroller.position()) > 0 and not mcontroller.groundMovement()

    while self.fireMode == "alt" do

        -- get change in angle
        local currentVector = vec2.rotate({1, 0}, activeItem.aimAngle(0, activeItem.ownerAimPosition()))
        local newAngle = totalAngle(initialVector, currentVector)
        local angleDelta = newAngle - oldAngle
        oldAngle = newAngle

        
        totalRotation = totalRotation + math.abs(angleDelta)

        if totalRotation >= 360 then
            noscope = true
        end
        if angleDelta * rotationDirection < 0 then break end
        
        if rotationDirection == 0 and math.abs(angleDelta) > 0 then
            rotationDirection = math.ceil(totalRotation) >= 360 - self.oppositeDirectionDetectionThreshold and -1 or 1
            if rotationDirection < 0 then
                totalRotation = totalRotation - 360
            end
            -- sb.logInfo(rotationDirection)
        end

        if angleDelta * rotationDirection > self.angleDeltaThreshold then break end

        animator.setSoundPitch("noscopeProgressLoop", 1 + 0.3 * math.min(totalRotation / 360, 2))
        activeItem.setScriptedAnimationParameter("altTotalAngle", totalRotation)

        world.debugLine(mcontroller.position(), vec2.add(mcontroller.position(), initialVector), "red")
        world.debugLine(mcontroller.position(), vec2.add(mcontroller.position(), currentVector), "cyan")
        
        coroutine.yield()
    end
    
    self.rotating = false

    if noscope then
        activeItem.setScriptedAnimationParameter("altTotalAngle", 360)
        self.noscopeTimer = self.noscopeTime
        status.addEphemeralEffect("project45noscopedamagebonus", self.noscopeTime)
        status.overConsumeResource("energy", status.resourceMax("energy"))
        
    else
        animator.stopAllSounds("noscopeProgressLoop")
        activeItem.setScriptedAnimationParameter("altTotalAngle", nil)
    end

end  

function Project45MLGNoScope:uninit()
end
