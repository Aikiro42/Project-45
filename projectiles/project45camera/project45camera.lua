require "/scripts/vec2.lua"

function init()
    self.speed = 0.5
end

function update(dt)
end

function updatePos(position, source, range, deadzone)
    -- refresh projectile
    projectile.setTimeToLive(10)

    local deadzone = deadzone or 5

    if world.magnitude(position, source) < range then end

    local newPos = position
    local oldPos = mcontroller.position()
    if world.magnitude(position, oldPos) > deadzone then

        local posVector = vec2.mul(vec2.norm(world.distance(position, oldPos)), self.speed)
        if world.magnitude(position, oldPos) < world.magnitude(posVector) then
            posVector = world.distance(position, oldPos)
        end
        newPos = vec2.add(oldPos, posVector)

        if world.magnitude(source, newPos) > range then
            posVector = vec2.mul(vec2.norm(world.distance(newPos, source)), range)
            newPos = vec2.add(source, posVector)
        end

        mcontroller.setPosition(newPos)
    end

    projectile.setTimeToLive(10)
end

function moveToSource(source)
    local oldPos = mcontroller.position()
    local posVector = world.distance(source, oldPos)
    local movMag = world.magnitude(posVector)
    if movMag < 0.5 then
        projectile.die()
    end
    posVector = vec2.mul(vec2.norm(posVector), math.min(movMag * 0.2, self.speed*8))
    
    local newPos = vec2.add(oldPos, posVector)
    world.debugLine(oldPos, newPos, "magenta")
    mcontroller.setPosition(newPos)
end

function lerpToSource(source, progress)
    mcontroller.setPosition(vec2.lerp(progress, mcontroller.position(), source))
end

function die()
    projectile.die()
end