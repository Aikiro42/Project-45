require "/scripts/vec2.lua"
function update()

  localAnimator.clearDrawables()
  localAnimator.clearLightSources()

  -- main animation stuff

  local laserOrig = animationConfig.animationParameter("laserOrig")
  local laserDest = animationConfig.animationParameter("laserDest")

  local projectileStack = animationConfig.animationParameter("projectileStack")
  local gunHand = animationConfig.animationParameter("gunHand")
  local aimPosition = animationConfig.animationParameter("aimPosition")
  
  local reloadGraceTimer = animationConfig.animationParameter("reloadGraceTimer")
  local reloading = animationConfig.animationParameter("reloading")
  local reloadTimer = animationConfig.animationParameter("reloadTimer")
  local reloadTime = animationConfig.animationParameter("reloadTime")
  local perfectReloadRange = animationConfig.animationParameter("perfectReloadRange")
  local barColor = animationConfig.animationParameter("barColor")

  local hitscanColor = animationConfig.animationParameter("hitscanColor")
  local laserColor = animationConfig.animationParameter("laserColor")

  local jammed = animationConfig.animationParameter("jammed")
  local jamScore = animationConfig.animationParameter("jamScore")

  
  -- laser
  if not (reloading or jammed) and laserOrig and laserDest then
    local laserLine = worldify(laserOrig, laserDest) -- already worldified
    localAnimator.addDrawable({
      line = laserLine,
      width = 0.25,
      fullbright = true,
      color = laserColor or {255,0,0}
    }, "Player-1")
  end

  -- bullet trails
  for i, projectile in ipairs(projectileStack) do
    local bulletLine = worldify(projectile.origin, projectile.destination)
    localAnimator.addDrawable({
      line = bulletLine,
      width = projectile.lifetime/projectile.maxLifetime,
      fullbright = true,
      color = hitscanColor or {255,255,255}
    }, "Player-1")
  end

  local offset = {gunHand == "primary" and -1.75 or 1.75, 0}

  -- reload indicator
  if reloading then
    renderReloadBar(reloadTimer, reloadTime, perfectReloadRange, aimPosition, offset, barColor)

  -- jammed indicator
  elseif jammed then
    renderJamBar(jamScore, aimPosition, offset)
  
  -- ammo counter
  else
    local ammo = animationConfig.animationParameter("ammoLeft")
    localAnimator.spawnParticle({
      type = "text",
      text= "^shadow;" .. ((ammo > 0) and ammo or (gunHand == "primary" and "L" or "R")),
      color = {225,225,225},
      size = 1,
      fullbright = true,
      flippable = false,
      layer = "front"
    }, vec2.add(aimPosition, offset))
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

function wrld(alpha)
  local xmax = world.size()[1]
  local dispvec = world.distance(playerPos, alpha)
  local a = vec2.add(alpha, playerPos)
  return a
end

function renderReloadBar(time, timeMax, perfect, position, offset, barColor, length, width, borderwidth)
  local length = length or 4
  local barWidth = width or 2
  local borderwidth = borderwidth or 1
  local barColor = barColor or {255,255,255}
  local offset = offset or {-4, 0}
  local arrowLength = 0.4

  local base = vec2.add(position, offset)
  local base_a = vec2.add(base, {0, -length/2}) -- start (bottom)
  local base_b = vec2.add(base, {0, length/2})  -- end   (top)
  local a, b

  -- render border
  a = vec2.add(base_a, {0, -borderwidth/8})
  b = vec2.add(base_b, {0, borderwidth/8})
  local reloadBarBorder = worldify(a, b)
  localAnimator.addDrawable({
    line = reloadBarBorder,
    width = barWidth + borderwidth*2,
    fullbright = true,
    color = {0,0,0}
  }, "ForegroundEntity+1")

  -- render bar
  local reloadLine = worldify(base_a, base_b)
  localAnimator.addDrawable({
    line = reloadLine,
    width = barWidth,
    fullbright = true,
    color = barColor
  }, "ForegroundEntity+1")

  -- render perfect range
  a = vec2.add(base_a, {0, perfect[1]*length/timeMax})
  b = vec2.add(base_a, {0, perfect[2]*length/timeMax})
  local perfectRange = {a, b}
  localAnimator.addDrawable({
    line = perfectRange,
    width = barWidth,
    fullbright = true,
    color = {143, 0, 255}
  }, "ForegroundEntity+1")

  -- render arrow
  a = vec2.add(base_a, {-arrowLength/2, time*length/timeMax})
  b = vec2.add(base_a, {arrowLength/2, time*length/timeMax})
  local arrow = {a, b}
  localAnimator.addDrawable({
    line = arrow,
    width = 0.75,
    fullbright = true,
    color = {255, 0, 0}
  }, "ForegroundEntity+1")

end

function renderJamBar(jamScore, position, offset, barColor, length, width, borderwidth)
  local length = length or 4
  local barWidth = width or 2
  local borderwidth = borderwidth or 1
  local barColor = barColor or {75,75,75}
  local offset = offset or {-4, 0}
  
  -- calculate bar stuff
  local base = vec2.add(position, offset)
  local base_a = vec2.add(base, {0, -length/2}) -- start (bottom)
  local base_b = vec2.add(base, {0, length/2})  -- end   (top)
  local a, b

  -- render border
  a = vec2.add(base_a, {0, -borderwidth/8})
  b = vec2.add(base_b, {0, borderwidth/8})
  local reloadBarBorder = worldify(a, b)
  localAnimator.addDrawable({
    line = reloadBarBorder,
    width = barWidth + borderwidth*2,
    fullbright = true,
    color = {0,0,0}
  }, "ForegroundEntity+1")

  -- render bar
  local unjamBar = worldify(base_a, base_b)
  localAnimator.addDrawable({
    line = unjamBar,
    width = barWidth,
    fullbright = true,
    color = barColor
  }, "ForegroundEntity+1")

  -- render jamScore
  a = base_a
  b = vec2.add(base_a, {0, jamScore*length})
  local jamScoreBar = {a, b}
  localAnimator.addDrawable({
    line = jamScoreBar,
    width = barWidth,
    fullbright = true,
    color = {255, 0, 0}
  }, "ForegroundEntity+1")

end