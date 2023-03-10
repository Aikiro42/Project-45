require "/scripts/vec2.lua"

function init()
    self.speed = 0.5
end

function update(dt)
end

function updatePos(position, source, range, deadzone, maxSpeed, maxSpeedDistance)
    projectile.setTimeToLive(10)

    local newPos = position -- set new position as cursor position
    local oldPos = mcontroller.position()

    -- if cursor is a bit further away from center of screen (where crosshair is)
    if world.magnitude(position, oldPos) > deadzone then

        local speed = (world.magnitude(newPos, oldPos) - deadzone)*maxSpeed/maxSpeedDistance

        -- let posVector be the displacement vector from the crosshair to the mouse position
        local posVector = vec2.mul(vec2.norm(world.distance(position, oldPos)), speed)

        -- let newPos be the crosshair displaced by posVector
        newPos = vec2.add(oldPos, posVector)

        -- limits distance of crosshair from source
        if world.magnitude(source, newPos) > range then
            -- let posVector be displacement vector from crosshair to the edge of the
            -- "zoom" range, relative to the mouse cursor
            posVector = vec2.mul(vec2.norm(world.distance(newPos, source)), range)
            newPos = vec2.add(source, posVector)
        end

        -- set new position
        mcontroller.setPosition(newPos)
    end

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
    if world.magnitude(source, mcontroller.position()) <= 0.1 then
        projectile.die()
    end
end

function jerk()
    local source = mcontroller.position()
    local shake_dir = vec2.mul({0, 1}, -0.5)
    shake_dir = vec2.rotate(shake_dir, 3.14 * sb.nrand(0.5 , 0.5))
    local newPos = vec2.add(source, shake_dir)
    mcontroller.setPosition(newPos)  
end

function die()
    projectile.die()
end