require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/project45/project45util.lua"

altInit = init or function()
end
altUpdate = update or function()
end

function init()
  altInit()
end

function update()

  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  altUpdate()

  local laserStart = animationConfig.animationParameter("dropLaserStart")
  local laserEnd = animationConfig.animationParameter("dropLaserEnd")

  if laserStart and laserEnd then
    local laserColor = animationConfig.animationParameter("dropLaserColor")
    local gradientColor = animationConfig.animationParameter("dropGradientColor")
    local gradientWidth = animationConfig.animationParameter("dropGradientWidth")
    local laserLine = project45util.worldify(laserStart, laserEnd)    
    -- project45util.drawGradient(laserEnd, laserStart, gradientWidth, 8, gradientColor, true, "Overlay")
    project45util.drawGradient(laserEnd, vec2.add(laserEnd, {0, 15}), gradientWidth, 8, gradientColor, true, "Overlay")
    -- project45util.drawGradient(laserEnd, vec2.add(laserEnd, {0, 10}), gradientWidth, 8, gradientColor, true, "Overlay")

    localAnimator.addDrawable({
      line = laserLine,
      width = 0.5,
      fullbright = true,
      color = laserColor
    }, "Overlay")

    
    local groundParticles = animationConfig.animationParameter("dropGroundParticles")
    if groundParticles then
      for _, particle in ipairs(groundParticles) do
        localAnimator.spawnParticle(particle, {sb.nrand(1, laserEnd[1]), laserEnd[2]})
      end
    end

  end

end
