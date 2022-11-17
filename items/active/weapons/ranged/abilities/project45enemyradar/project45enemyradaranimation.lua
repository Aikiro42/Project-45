require "/scripts/vec2.lua"
function update()
    -- laser
    local enemyEntities = animationConfig.animationParameter("enemyEntities")
    local radius = animationConfig.animationParameter("radius")
    local offset = animationConfig.animationParameter("offset")
    for i, enemyEntity in ipairs(enemyEntities) do
        
        local arrowPos = vec2.add(activeItemAnimation.ownerPosition(), {offset * math.cos(enemyEntity.angle), offset * math.sin(enemyEntity.angle)})
        local distanceTextPos = vec2.add(activeItemAnimation.ownerPosition(), {(offset*1.25) * math.cos(enemyEntity.angle), (offset*1.25) * math.sin(enemyEntity.angle)})
        local indicatorColor = {0, 255, 0, 100}
        if enemyEntity.canDamageOwner then
            if enemyEntity.aggressive then
                indicatorColor={255, 0, 0, 100}
            else
                indicatorColor = {255,200, 0, 100}
            end
        end
        -- render arrow
        localAnimator.addDrawable({
            image="/items/active/weapons/ranged/abilities/project45enemyradar/project45enemyradararrow.png?fade=".. colorToHex(indicatorColor)  .."=1?multiply=FFFFFF" .. string.upper(string.format("%x", math.floor(255*(1 - enemyEntity.distance/radius)))),
            position=arrowPos,
            rotation=enemyEntity.angle,
            fullbright=true,
            centered=true
        }, "Overlay")

        -- render distance text
        localAnimator.spawnParticle({
            type = "text",
            text= "^shadow;" .. math.floor(enemyEntity.distance),
            color = indicatorColor,
            size = 0.3,
            fullbright = true,
            flippable = false,
            layer = "front"
          }, distanceTextPos)

    end
end

function colorToHex(colorArray)
    return string.upper(string.format("%02x", colorArray[1]))
    .. string.upper(string.format("%02x", colorArray[2])) 
    .. string.upper(string.format("%02x", colorArray[3]))
end