require "/scripts/vec2.lua"

function update(dt)
    if shouldDie() then projectile.die() end
end

function shouldDie()
    return mcontroller.isColliding()
    -- return world.lineTileCollision(mcontroller.position(), vec2.add(mcontroller.position(), vec2.norm(mcontroller.velocity())))
end