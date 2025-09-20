require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/project45/project45util.lua"

local textSize = 0.5
tester_oldUpdate = update or function() end
function update()

    localAnimator.clearDrawables()
    localAnimator.clearLightSources()
    tester_oldUpdate()
    -- laser
    local laser = {}
    laser.origin = animationConfig.animationParameter("testLaserOrigin")
    laser.destination = animationConfig.animationParameter("testLaserDestination")
    laser.color = {255, 215, 0, 128}
    laser.width = 2

    if laser.origin and laser.destination then

        local laserLine = worldify(laser.origin, laser.destination)
        localAnimator.addDrawable({
            line = laserLine,
            width = laser.width,
            fullbright = true,
            color = laser.color
        }, "ForegroundEntity+1")
    end
    
end

function posText(pos, up, prefix)
    local offset = 2
    localAnimator.spawnParticle({
        type = "text",
        text= "^shadow;" .. (prefix or "") .. "{" .. util.round(pos[1], 1) .. ", " .. util.round(pos[2], 1) .. "}",
        color = {255,255,255},
        size = textSize,
        fullbright = true,
        flippable = false,
        layer = "front"
    }, vec2.add(pos, {0, up and offset or -offset}))
end

function drawText(t, pos, prefix)
    pos = pos or vec2.add(activeItemAnimation.ownerPosition(), {0, -1})
    localAnimator.spawnParticle({
        type = "text",
        text= "^shadow;" .. (prefix or "") .. t,
        color = {255,255,255},
        size = textSize,
        fullbright = true,
        flippable = false,
        layer = "front"
    }, pos)
end


-- Calculates the line from pos1 to pos2
-- that allows `localAnimator.addDrawable()`
-- to render it correctly
function worldify(pos1, pos2)

  return project45util.worldify(pos1, pos2)

end