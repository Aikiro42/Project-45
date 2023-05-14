require "/scripts/vec2.lua"
require "/scripts/util.lua"

function update()
    
    localAnimator.clearDrawables()
    localAnimator.clearLightSources()

    local cos = animationConfig.animationParameter("altTotalAngle")

    if cos then
      localAnimator.spawnParticle({
        type = "text",
        text= "^shadow;" .. util.round(cos, 1),
        color = cos < 360 and "#FFFFFFAA" or "#FFAA00FF",
        size = 1,
        fullbright = true,
        flippable = false,
        layer = "front"
      }, vec2.add(activeItemAnimation.ownerAimPosition(), {3, 0}))
    end


    
end