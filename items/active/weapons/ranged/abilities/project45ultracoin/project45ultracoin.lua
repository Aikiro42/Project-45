require "/scripts/util.lua"
require "/scripts/vec2.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45Ultracoin = WeaponAbility:new()

function Project45Ultracoin:init()
    self.cooldownTimer = 0
end

function Project45Ultracoin:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)
    
    self.cooldownTimer = self.cooldownTimer - self.dt

    if self.fireMode == "alt"
    and self.cooldownTimer <= 0
    and self.pixelCost < player.currency("money")
    then
        local vector = vec2.norm(world.distance(activeItem.ownerAimPosition(), mcontroller.position()))
        vector = vec2.rotate(vector, sb.nrand(self.inaccuracy, 0))
        
        animator.playSound("throwPing")
        world.spawnMonster(
            "project45-ultracoin",
            mcontroller.position(),
            {
                initialMomentum = vec2.mul(vector, self.throwForce),
                parentEntityId = activeItem.ownerEntityId()
            })
        player.consumeCurrency("money", self.pixelCost)
        self.cooldownTimer = self.fireTime
    end

end

function Project45Ultracoin:uninit()
end