function update()
    -- laser
    local laser = {}
    laser.origin = animationConfig.animationParameter("laserOrigin")
    laser.destination = animationConfig.animationParameter("laserDestination")
    laser.color = animationConfig.animationParameter("laserColor")

    if laser.origin and laser.destination then
    local laserLine = worldify(laser.origin, laser.destination)
    localAnimator.addDrawable({
        line = laserLine,
        width = 0.2,
        fullbright = true,
        color = laser.color
    }, "Player+1")
    end
end