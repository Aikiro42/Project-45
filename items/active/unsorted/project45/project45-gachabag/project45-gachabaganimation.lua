require "/scripts/vec2.lua"

function init()
end

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  local pullCounter = animationConfig.animationParameter("pullCounter", 0)
  localAnimator.spawnParticle({
    type = "text",
    text= "^shadow;Keys",
    color = {247,190,121},
    size = 0.5,
    fullbright = true,
    flippable = false,
    layer = "front"
  }, vec2.add(activeItemAnimation.ownerPosition(), {-activeItemAnimation.ownerFacingDirection()*2, -0.5}))
  localAnimator.spawnParticle({
    type = "text",
    text= "^shadow;" .. pullCounter,
    color = {247,190,121},
    size = 1,
    fullbright = true,
    flippable = false,
    layer = "front"
  }, vec2.add(activeItemAnimation.ownerPosition(), {-activeItemAnimation.ownerFacingDirection()*2, 0.5}))
end