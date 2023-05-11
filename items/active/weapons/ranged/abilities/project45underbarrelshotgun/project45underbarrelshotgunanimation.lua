require "/scripts/vec2.lua"

function update()
    
    localAnimator.clearDrawables()
    localAnimator.clearLightSources()

    local aimPos = activeItemAnimation.ownerAimPosition()
    local underbarrelGunAmmoIndicatorOffset = animationConfig.animationParameter("underbarrelGunAmmoIndicatorOffset")
    local underbarrelGunAmmo = animationConfig.animationParameter("underbarrelGunAmmo")
    local underbarrelGunState = animationConfig.animationParameter("underbarrelGunState")

    localAnimator.addDrawable({
        image = "/items/active/weapons/ranged/abilities/project45underbarrelshotgun/indicator.png:" .. underbarrelGunAmmo .. "." .. underbarrelGunState,
        position = vec2.add(aimPos, underbarrelGunAmmoIndicatorOffset),
        color = {255,255,255,128},
        fullbright = true,
      }, "ForegroundEntity+1")

    
end