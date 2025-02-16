require "/scripts/util.lua"
require "/items/active/weapons/project45neoweapon.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45PhaseShift = WeaponAbility:new()

function Project45PhaseShift:init()
    self.phasing = false
    self.shiftHeldTimer = -1

    storage.project45GunState.damageModifiers['phaseShiftDamageMult'] = nil
    
    storage.dodjiboru = storage.dodjiboru or self.dodgeCooldownTime

    self.debugTimer = 0
end

function Project45PhaseShift:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    -- debug

    storage.dodjiboru = math.max(0, storage.dodjiboru - self.dt)

    self.debugTimer = math.max(0, self.debugTimer - self.dt)
    if self.debugTimer == 0 then
        self.debugTimer = 0.5
    end

    if shiftHeld and not self.weapon.overrideShiftAction then

        -- start timer if not started already
        if self.shiftHeldTimer < 0 then self.shiftHeldTimer = 0 end

        -- increment timer while shift is held
        self.shiftHeldTimer = self.shiftHeldTimer + self.dt
    else
        -- if timer was started
        -- and player triggered a dodge
        if 0 < self.shiftHeldTimer
        and self.shiftHeldTimer < self.shiftHeldTime
        and not self.weapon.currentAbility
        and storage.dodjiboru == 0
        and status.overConsumeResource("energy", status.resourceMax("energy") * self.dodgeEnergyCostPercent)
        and not self.phasing
        then
            self:setState(self.dodge)
            storage.dodjiboru = self.dodgeCooldownTime
        end

        self.shiftHeldTimer = -1

    end

    if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
        self.triggered = false
    end

    if self.phasing then
        status.addEphemeralEffect("project45dash")
        if status.overConsumeResource("energy", status.resourceMax("energy") * self.energyUsageRatePercent * self.dt) then
            mcontroller.controlModifiers({
                speedModifier = self.movementSpeedFactor,
                airJumpModifier = self.jumpHeightFactor,
                runningSuppressed = false
            })
        else
            self:endPhaseShift()
        end    
    end
    
    if self.fireMode == "alt"
    and not self.weapon.currentAbility
    and not self.triggered
    then

        if status.resourcePositive("energy") then
            if not self.phasing then
                self:beginPhaseShift()
            else
                self:endPhaseShift()
            end        
        else
            animator.playSound("error")
        end

        self.triggered = true
    
    end

end

function Project45PhaseShift:dodge()

    local projectileId = world.spawnProjectile(
        "invisibleprojectile",
        mcontroller.position(),
        activeItem.ownerEntityId(),
        {1, 0},
        false,
        {
            power=0,
            timeToLive=0,
            damageType="NoDamage",
            actionOnReap={
                {
                    action="particle",
                    specification="project45realityshard01"
                },
                {
                    action="particle",
                    specification="project45realityshard02"
                },
                {
                    action="particle",
                    specification="project45realityshard03"
                },
                {
                    action="particle",
                    specification="project45realityshard04"
                },
            }
        }
    )

    local dashDirection
    if mcontroller.xVelocity() ~= 0 then
      dashDirection = mcontroller.movingDirection()
    else
      dashDirection = mcontroller.facingDirection()
    end

    animator.playSound("dodge")
    animator.playSound("phaseStart")

    if not status.resourcePositive("energy") then
        animator.playSound("noEnergy")
    end

    status.addEphemeralEffect("project45dash", self.dodgeStatusTime)

    util.wait(self.dodgeTime, function(dt)
      mcontroller.setVelocity({self.dodgeSpeed*dashDirection, 0})
    end)

    mcontroller.setXVelocity(mcontroller.xVelocity() * self.dodgeEndVelocityMult)
  
    storage.dodgeCooldownTimer = self.dodgeCooldownTime
end


function Project45PhaseShift:beginPhaseShift()
    self.phasing = true
    local projectileId = world.spawnProjectile(
        "invisibleprojectile",
        mcontroller.position(),
        activeItem.ownerEntityId(),
        {1, 0},
        false,
        {
            power= 0,
            timeToLive=0,
            damageType="NoDamage",
            actionOnReap={
                {
                    action="particle",
                    specification="project45realityshard01"
                },
                {
                    action="particle",
                    specification="project45realityshard02"
                },
                {
                    action="particle",
                    specification="project45realityshard03"
                },
                {
                    action="particle",
                    specification="project45realityshard04"
                },
            }
        }
    )
    storage.project45GunState.damageModifiers['phaseShiftDamageMult'] = {
        type="mult",
        value=0
    }
    animator.playSound("phaseStart")
    animator.playSound("phaseLoop", -1)
end

function Project45PhaseShift:endPhaseShift()
    self.phasing = false
    local projectileId = world.spawnProjectile(
        "invisibleprojectile",
        mcontroller.position(),
        activeItem.ownerEntityId(),
        {1, 0},
        false,
        {
            power=0,
            timeToLive=0,
            actionOnReap={
                {
                    action="particle",
                    specification="project45realityshard01"
                },
                {
                    action="particle",
                    specification="project45realityshard02"
                },
                {
                    action="particle",
                    specification="project45realityshard03"
                },
                {
                    action="particle",
                    specification="project45realityshard04"
                },
            }
        }
    )
    if not status.resourcePositive("energy") then
        animator.playSound("noEnergy")
    end
    storage.project45GunState.damageModifiers['phaseShiftDamageMult'] = nil
    animator.playSound("phaseEnd")
    animator.stopAllSounds("phaseLoop")
end

function Project45PhaseShift:uninit()
    animator.stopAllSounds("phaseLoop")
    storage.project45GunState.damageModifiers['phaseShiftDamageMult'] = nil
end