require "/scripts/vec2.lua"
function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()

  local projectileStack = animationConfig.animationParameter("projectileStack")

  local aimPosition = animationConfig.animationParameter("aimPosition")
  local ammo = animationConfig.animationParameter("ammo")
  local ammoMax = animationConfig.animationParameter("ammoMax")

  local jamAmount = animationConfig.animationParameter("jamAmount")

  local reloadTimer = animationConfig.animationParameter("reloadTimer")
  local reloadTime = animationConfig.animationParameter("reloadTime")
  local perfectReloadRange = animationConfig.animationParameter("perfectReloadRange")
  local goodReloadRange = animationConfig.animationParameter("goodReloadRange")
  local reloadRating = animationConfig.animationParameter("reloadRating")

  local muzzlePos = animationConfig.animationParameter("muzzlePos")

  local muzzleSmokeTimer = animationConfig.animationParameter("muzzleSmokeTimer")
  local muzzleSmokeTime = animationConfig.animationParameter("muzzleSmokeTime")

  local muzzleFlash = animationConfig.animationParameter("muzzleFlash")
  local muzzleFlashPos = activeItemAnimation.ownerPosition()
  local muzzleFlashColor = {0, 0, 0}

  local reloadBarColors = {
    bad = {255, 0, 0},
    good = {0, 255, 255},
    perfect = {255, 255, 0}
  }

  local reloadBarColor = reloadBarColors[reloadRating]
  local jamBarColor = {255, 128, 0}  

  local gunHand = animationConfig.animationParameter("gunHand")
  local offset = {gunHand == "primary" and -1.75 or 1.75, 0}

  -- smoke
  --[[
  local muzzleSmokeProgress = 1 - muzzleSmokeTimer/muzzleSmokeTime
  if muzzleSmokeProgress < 1 then
    localAnimator.spawnParticle(
      {
        type = "ember",
        size = 0.5 + 0.2 * (1 - muzzleSmokeProgress),
        color = {200, 200, 200, 100 * (-muzzleSmokeProgress^4 + 1)},
        fade = 0.9,
        initialVelocity = {(1 - muzzleSmokeProgress)*5, -1 + muzzleSmokeProgress*6},
        approach = {-0.1, 5},
        finalVelocity = {0, 5},
        destructionTime = 0.9,
        layer = "front",
        collidesLiquid = true,
        variance = {
          initialVelocity = {0.5 * (1 - muzzleSmokeProgress), 0.5 * (1 - muzzleSmokeProgress)},
          finalVelocity = {0.2, 0},
          size = 0.5
        }
      },
      muzzlePos
    )
  end
  --]]

  if 0 < muzzleSmokeTimer and muzzleSmokeTimer < muzzleSmokeTime - 0.1 then

    localAnimator.spawnParticle(
      "project45muzzlesmoke",
      muzzlePos
    )

  end

  -- render hitscan trails
  for i, projectile in ipairs(projectileStack) do
    local bulletLine = worldify(projectile.origin, projectile.destination)
    muzzleFlashColor = projectile.color or {0, 0, 0}
    localAnimator.addDrawable({
      line = bulletLine,
      width = (projectile.width or 1) * projectile.lifetime/projectile.maxLifetime,
      fullbright = true,
      color = projectile.color or {0, 0, 0}
    }, "Player-1")
  end

  -- render muzzle flash
  if muzzleFlash then
    localAnimator.addLightSource({
      position = muzzlePos,
      color = muzzleFlashColor,
      pointLight = true,
      pointBeam = 0.3,
    })
  end

  if reloadTimer >= 0 then
    renderReloadBar(reloadTimer, reloadTime, goodReloadRange, perfectReloadRange, string.upper(reloadRating), aimPosition, offset, reloadBarColor)
    offset = vec2.add(offset, offset)
  end

  if jamAmount > 0 then
    renderJamBar(jamAmount, aimPosition, offset)
    offset = vec2.add(offset, offset)
  end

  local ammoDisplay = ammo
  if ammo < 0 then ammoDisplay = "E" end

  -- bullet counter
  localAnimator.spawnParticle({
    type = "text",
    text= "^shadow;" .. ammoDisplay,
    color = (jamAmount > 0 and jamBarColor) or (reloadRating == "perfect" and ammo > 0 and {255, 255, 0}) or (ammo == ammoMax and {100, 255, 255}) or {203, 203, 203},
    size = 1,
    fullbright = true,
    flippable = false,
    layer = "front"
  }, vec2.add(aimPosition, offset))

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

function renderReloadBar(time, timeMax, good, perfect, rating, position, offset, barColor, length, width, borderwidth)
  local length = length or 4
  local barWidth = width or 2
  local borderwidth = borderwidth or 1
  local barColor = barColor or {255,255,255}
  local offset = offset or {-4, 0}
  local arrowLength = 0.4
  local textSize = 0.5

  local base = vec2.add(position, offset)
  local base_a = vec2.add(base, {0, -length/2}) -- start (bottom)
  local base_b = vec2.add(base, {0, length/2})  -- end   (top)
  local a, b, o

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
  
  -- render text
  o = vec2.add(base_b, {0, borderwidth/8 + textSize})
  localAnimator.spawnParticle({
    type = "text",
    text= "^shadow;" .. rating,
    color = {203, 203, 203},
    size = textSize,
    fullbright = true,
    flippable = false,
    layer = "front"
  }, o)

  -- render bar
  local reloadLine = worldify(base_a, base_b)
  localAnimator.addDrawable({
    line = reloadLine,
    width = barWidth,
    fullbright = true,
    color = barColor
  }, "ForegroundEntity+1")

  -- render good range
  a = vec2.add(base_a, {0, good[1]*length/timeMax})
  b = vec2.add(base_a, {0, good[2]*length/timeMax})
  local perfectRange = {a, b}
  localAnimator.addDrawable({
    line = perfectRange,
    width = barWidth,
    fullbright = true,
    color = {143, 0, 255}
  }, "ForegroundEntity+1")

  -- render perfect range
  a = vec2.add(base_a, {0, perfect[1]*length/timeMax})
  b = vec2.add(base_a, {0, perfect[2]*length/timeMax})
  local perfectRange = {a, b}
  localAnimator.addDrawable({
    line = perfectRange,
    width = barWidth,
    fullbright = true,
    color = {199, 128, 255}
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
    color = {255, 128, 0}
  }, "ForegroundEntity+1")

end