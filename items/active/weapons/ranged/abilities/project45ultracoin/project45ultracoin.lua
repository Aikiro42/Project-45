require "/scripts/util.lua"
require "/scripts/vec2.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45Ultracoin = WeaponAbility:new()

function Project45Ultracoin:init()
    self.cooldownTimer = 0
    self.ammoPerToss = math.max(0, self.ammoPerToss or 0)

    self.maxChainDistsance = self.maxChainDistsance or 75

    -- i mean sure you could modify these in the weaponability json
    -- but i won't accept responsibility for when your world crashes
    -- due to too many entities
    self.limitEntities = true
    self.entityThreshold = self.entityThreshold or 64

    self.aimOffset = self.aimOffset or {0, 0}
end

function Project45Ultracoin:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)
    self.cooldownTimer = self.cooldownTimer - self.dt

    if self.fireMode == "alt"
    and self.cooldownTimer <= 0
    then
        if self.pixelCost < player.currency("money")
        and status.consumeResource("energy", self.energyCost)
        and ((self.ammoPerToss > 0 and (storage.project45GunState.ammo or 2) > 1) or self.ammoPerToss == 0)
        and self:currentEntityCount() < self.entityThreshold
        then

            local force = self.throwForce * sb.nrand(self.inaccuracy.throwForce, 1)
            local vector = self:aimVector(self.aimOffset)
            vector = vec2.rotate(vector, sb.nrand(self.inaccuracy.angle, 0))
            
            animator.playSound("toss")
            world.spawnMonster(
                self.coinMonster,
                mcontroller.position(),
                sb.jsonMerge(self.coinParameters or {},
                {
                    initialMomentum = vec2.mul(vector, self.throwForce),
                    ownerEntityId = activeItem.ownerEntityId(),
                    ownerDamageTeam = world.entityDamageTeam(activeItem.ownerEntityId())
                }))
            player.consumeCurrency("money", self.pixelCost)
            if storage.project45GunState.ammo then
                storage.project45GunState.ammo = storage.project45GunState.ammo - self.ammoPerToss
            end
        else
            animator.playSound("error")        
        end
        self.cooldownTimer = self.fireTime
    end

end

function Project45Ultracoin:aimVector(aimOffset)
    return vec2.norm(
            world.distance(
                vec2.add(activeItem.ownerAimPosition(), aimOffset or {0, 0}),
                mcontroller.position()
            )
    )
end

function Project45Ultracoin:currentEntityCount()
    local detectedEntities = world.entityQuery(mcontroller.position(), self.maxChainDistsance, {
        withoutEntityId = entity.id(),
        includedTypes = {"creature"},
        order = "nearest"
    })
    return #detectedEntities
end

function Project45Ultracoin:uninit()
end