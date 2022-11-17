require "/scripts/vec2.lua"

function update()

    localAnimator.clearDrawables()
    localAnimator.clearLightSources()
    
    local laser = {}
    laser.origin = animationConfig.animationParameter("laserOrigin")
    laser.destination = animationConfig.animationParameter("laserDestination")

    if laser.origin and laser.destination then
        local laserLine = worldify(laser.origin, laser.destination)
        localAnimator.addDrawable({
            line = laserLine,
            width = 0.3,
            fullbright = true,
            color = {144, 0, 255}
        }, "Player-1")  
    end
end

function worldify(alfa, beta)
    -- local playerPos = animationConfig.animationParameter("playerPos")
    local a = alfa
    local b = beta
    local xmax = world.size()[1]
    local dispvec = world.distance(b, a)
    if a[1] > xmax/2 then 
        a[1] = -1 * (xmax - a[1])
    end
    b = vec2.add(a, dispvec)
    return {a, b}
end
  