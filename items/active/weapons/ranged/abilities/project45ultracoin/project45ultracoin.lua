require "/scripts/util.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45Ultracoin = WeaponAbility:new()

function Project45Ultracoin:init()
    self.cooldownTime = 0.1
    self.cooldownTimer = 0
end

function Project45Ultracoin:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)
    
    self.cooldownTimer = self.cooldownTimer - self.dt

    if self.fireMode == "alt"
    and self.cooldownTimer <= 0
    then
        world.spawnMonster(
            "project45-ultracoin",
            mcontroller.position(),
            {
                initialMomentum = {mcontroller.facingDirection() * 1.5*math.random(),5},
                parentEntityId = activeItem.ownerEntityId()
            })
        self.cooldownTimer = self.cooldownTime
    end

end

function Project45Ultracoin:uninit()
end