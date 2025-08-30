require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"
require "/items/active/weapons/project45neoweapon.lua"
require "/scripts/project45/project45util.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

require "/items/active/weapons/ranged/abilities/project45gunfire/formulas.lua"

Project45ScarletFlash = WeaponAbility:new()

function Project45ScarletFlash:init()
    self.cooldownTimer = self.cooldownTime
    self.stacks = 0
    self.stackTimer = 0
    -- find project45gunfire
    for i, ability in ipairs(self.weapon.abilities) do
        if ability.name == "_Project45GunFire_" then
            self.abilityIndex = i
            break
        end
    end
    animator.setParticleEmitterActive("charging", false)
    animator.stopAllSounds("activate")
end

function Project45ScarletFlash:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

    if self.fireMode ~= "alt" then
        self.triggered = false
    end

    if self.fireMode == "alt"
    and self.cooldownTimer <= 0
    and not self.weapon.currentAbility
    and not self.triggered
    then
        if not status.resourceLocked("energy") then
            self:setState(self.activating)
        end
        self.cooldownTimer = self.cooldownTime
        self.triggered = true
    end

end

function Project45ScarletFlash:addStack()
    self.stacks = math.min(5, self.stacks + 1)
    self.stackTimer = 5
end

function Project45ScarletFlash:activating()
    local slashes = self.slashCount
    local slashRadius = self.slashDetectionRadius
    local slashFuzz = vec2.rotate(self.slashFuzz, activeItem.aimAngle(0, activeItem.ownerAimPosition()))
    
    local abilityDamage = self:calculateDamage()

    status.overConsumeResource("energy", status.resourceMax("energy"))
    local savedPosition = mcontroller.position()
    local aimVec = self:aimVector()
    
    -- initial slow slash projectile
    animator.playSound("activate")
    world.spawnProjectile(
        "project45scarletflash",
        self:aimPosition(aimVec),
        activeItem.ownerEntityId(),
        aimVec,
        false,
        {
            power=abilityDamage
        }
    )
    
    animator.setParticleEmitterActive("charging", true)
    util.wait(self.explosionDelay)
    animator.setParticleEmitterActive("charging", false)

    -- sfx projectile
    world.spawnProjectile(
            "project45_scarletflashflurry",
            mcontroller.position(),
            activeItem.ownerEntityId(),
            {1, 0},
            true,
            {
                power=abilityDamage,
                actionOnSpawn={
                    {
                        action="sound",
                        options={"/sfx/project45neosfx/ability/project45scarletflash/scarletflash2.ogg"}
                    }
                }
            }
        )
    
    -- query entities
    local detectedEntities = world.entityQuery(savedPosition, slashRadius, {
        withoutEntityId = activeItem.ownerEntityId(),
        includedTypes = {"creature"},
        order = "nearest"
        })
    
    if #detectedEntities <= 0 then
        detectedEntities = {activeItem.ownerEntityId()}
    end

    local slashedEntities = set.new(detectedEntities)

    local slashAngle = 2*math.pi/slashes
    local damagePerSlash = abilityDamage/5
    for i=0, slashes do
        
        -- get entity info
        local entityIndex = (i % #detectedEntities) + 1
        local id = detectedEntities[entityIndex]
        local position
        if not world.entityExists(id) and world.entityCanDamage(activeItem.ownerEntityId(), id) then
            id = activeItem.ownerEntityId()
            position = vec2.add(
                savedPosition,
                vec2.rotate({sb.nrand(slashRadius, 0), 0}, sb.nrand(2*math.pi, 0))
            )
        else
            position = world.entityPosition(detectedEntities[entityIndex])
        end

        -- spawn slash at entity
        world.spawnProjectile(
            "project45scarletslash",
            slashedEntities[id] and position or vec2.add(position, {
                sb.nrand(slashFuzz[1], 0),
                sb.nrand(slashFuzz[2], 0)
            }),
            slashedEntities[id] and id or activeItem.ownerEntityId(),
            vec2.rotate({1, 0}, slashedEntities[id] and (math.pi/4) or slashAngle*i),
            slashedEntities[id],
            {
                power=damagePerSlash,
                damageTeam = slashedEntities[id] and entity.damageTeam() or nil,
                actionOnReap= slashedEntities[id] and {
                    {
                        action="projectile",
                        inheritDamageFactor=1,
                        fuzzAngle=360,
                        type="project45_scarletflashflurry"
                  
                    }
                } or {
                    {
                        action="projectile",
                        inheritDamageFactor=1,
                        fuzzAngle=360,
                        type="project45_fleetlyfadingexplosion"
                  
                    },
                    {
                        action="projectile",
                        inheritDamageFactor=0,
                        fuzzAngle=360,
                        type="project45-stdexplosionshockwave"
                  
                    }
                }
            }
        )
        slashedEntities[id] = false
        util.wait(self.slashSpawnDelay)
    end


end

function Project45ScarletFlash:aimPosition(aimVector)
    local aimPos = mcontroller.position()
    local init = vec2.add(mcontroller.position(), vec2.mul(aimVector, -20))
    local dist = world.distance(init, mcontroller.position())
    aimPos = vec2.add(mcontroller.position(), dist)
    return aimPos
end

function Project45ScarletFlash:aimVector()
    local aimVec = vec2.rotate({1, 0}, activeItem.aimAngle(0, activeItem.ownerAimPosition()))
    return aimVec
end

function Project45ScarletFlash:calculateDamage(ability)
    if self.abilityIndex and not ability then
        ability = self.weapon.abilities[self.abilityIndex]
    end
    if ability then
        self.baseDamage = ability.baseDamage
            * storage.project45GunState.damageModifiers["reloadDamageMult"].value
            * storage.project45GunState.damageModifiers["stockAmmoDamageMult"].value
            * (ability.passiveDamageMult or 1)
            -- * ability:calculateCritDamage(false, storage.project45GunState.reloadRating)
            * formulas.critDamage(0, ability.critDamageMult, false, storage.project45GunState.reloadRating)

    else
        self.baseDamage = status.resourceMax("energy") * self.energyScaleFactor
    end
    local remainingHealthMult = 1 + ((1 - status.resourcePercentage("health")) * self.healthScaleFactor)
    return self.baseDamage*remainingHealthMult
end

function Project45ScarletFlash:uninit()
    animator.stopAllSounds("activate")
end