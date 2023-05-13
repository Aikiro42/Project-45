require "/scripts/vec2.lua"

local warningTriggered = false

synthethikmechanics_altUpdate = update or function()
    if not warningTriggered then
      warningTriggered = true
      -- sb.logInfo("[PROJECT 45] (" .. animationConfig.animationParameter("shortDescription") .. ") Failed to get alt-ability animation script update function. Weapon may be one-handed, not have an alt-ability, or may not have an alt-ability animation script.")
    end
  end

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  
  synthethikmechanics_altUpdate()
  if not warningTriggered then
    warningTriggered = true
    -- sb.logInfo("[PROJECT 45] Obtained alt-ability animation update script.")
  end

  local usedByNPC =  animationConfig.animationParameter("usedByNPC")

  local projectileStack = animationConfig.animationParameter("projectileStack")
  local primaryProjectileSpeed = animationConfig.animationParameter("primaryProjectileSpeed")

  local beamLine = animationConfig.animationParameter("beamLine")
  local beamWidth = animationConfig.animationParameter("beamWidth")
  local beamInnerWidth = animationConfig.animationParameter("beamInnerWidth")
  local beamColor = animationConfig.animationParameter("beamColor")

  local aimPosition = animationConfig.animationParameter("aimPosition")
  local aimAngle = animationConfig.animationParameter("aimAngle")
  local ammo = animationConfig.animationParameter("ammo")
  local ammoMax = animationConfig.animationParameter("ammoMax")

  local jamAmount = animationConfig.animationParameter("jamAmount")

  local reloadTimer = animationConfig.animationParameter("reloadTimer")
  local reloadTime = animationConfig.animationParameter("reloadTime")
  local perfectReloadRange = animationConfig.animationParameter("perfectReloadRange")
  local goodReloadRange = animationConfig.animationParameter("goodReloadRange")
  local reloadRating = animationConfig.animationParameter("reloadRating")

  local chargeTimer = animationConfig.animationParameter("chargeTimer")
  local chargeTime = animationConfig.animationParameter("chargeTime")
  local overchargeTime = animationConfig.animationParameter("overchargeTime")

  local muzzlePos = animationConfig.animationParameter("muzzlePos")

  local muzzleSmokeTimer = animationConfig.animationParameter("muzzleSmokeTimer")
  local muzzleSmokeTime = animationConfig.animationParameter("muzzleSmokeTime")

  local muzzleFlash = animationConfig.animationParameter("muzzleFlash")
  local muzzleFlashPos = activeItemAnimation.ownerPosition()
  local muzzleFlashColor = {0, 0, 0}

  local reloadBarColors = {
    bad = {255, 30, 0},
    good = {0, 195, 255},
    perfect = {255, 187, 0}
  }

  local ammoCounterColors = {
    bad = {255, 181, 171},
    good = {133, 226, 255},
    perfect = {255, 220, 124}
  }

  local reloadBarColor = reloadBarColors[reloadRating]
  local jamBarColor = {255, 128, 0}
  local jamAmmoCounterColor = {255, 193, 131}

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
    muzzleFlashColor = projectile.color or {0, 0, 0}
    -- don't calculate the bullet line when the origin is the same as the destination
    -- there is no scanline if projectiles are shot
    if projectile.origin ~= projectile.destination then
      local bulletLine = worldify(projectile.origin, projectile.destination)
      localAnimator.addDrawable({
        line = bulletLine,
        width = (projectile.width or 1) * projectile.lifetime/projectile.maxLifetime,
        fullbright = true,
        color = projectile.color or {0, 0, 0}
      }, "Player-1")
    end
  end

  -- render beam
  if beamLine then
    beamLine = worldify(beamLine[1], beamLine[2])
    localAnimator.addDrawable({
      line = beamLine,
      width = beamWidth,
      fullbright = true,
      color = beamColor or {255,255,255}
    }, "Player-1")
    localAnimator.addDrawable({
      line = beamLine,
      width = beamInnerWidth,
      fullbright = true,
      color = {255,255,255}
    }, "Player-1")
    localAnimator.addLightSource({
      position = beamLine[1],
      color = beamColor,
      pointLight = true,
      pointBeam = 0.3,
    })
    localAnimator.addLightSource({
      position = beamLine[2],
      color = beamColor,
      pointLight = true,
      pointBeam = 0.3,
    })
    localAnimator.spawnParticle(
      "project45beamendsmoke",
      beamLine[2]
    )
    for i = 1, 3 do
      localAnimator.spawnParticle(
        "project45beamendspark",
        beamLine[2]
      )
    end
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

  -- render reload bar if reloading
  if not usedByNPC and reloadTimer >= 0 then
    renderReloadBar(reloadTimer, reloadTime, goodReloadRange, perfectReloadRange, string.upper(reloadRating), aimPosition, offset, reloadBarColor)
    offset = vec2.add(offset, offset)
  end

  -- render jam bar if jammed
  if not usedByNPC and jamAmount > 0 then
    renderJamBar(jamAmount, aimPosition, offset)
    offset = vec2.add(offset, offset)
  end

  -- render horizontal charge bar if charging
  if not usedByNPC and chargeTimer > 0 then
    renderChargeBar(chargeTimer, chargeTime, overchargeTime, aimPosition)
  end


  local ammoDisplay = ammo
  if ammo < 0 then ammoDisplay = "E" end
  offset[1] = offset[1] + (offset[1] > 0 and (string.len("" .. ammoDisplay)-1)/2 or -(string.len("" .. ammoDisplay)-1)/2)

  -- bullet counter
  local ammoCounterColor = {203, 203, 203}
  if jamAmount > 0 then
    ammoCounterColor = jamAmmoCounterColor
  else
    if reloadRating ~= "ok" and ammo > 0 then
      ammoCounterColor = ammoCounterColors[reloadRating]
    else
      ammoCounterColor = {203, 203, 203}
    end
  end
  
  if not usedByNPC then
    localAnimator.spawnParticle({
      type = "text",
      text= "^shadow;" .. ammoDisplay,
      color = ammoCounterColor,
      size = 1,
      fullbright = true,
      flippable = false,
      layer = "front"
    }, vec2.add(aimPosition, offset))
  end

  -- laser
  local laser = {}
  laser.origin = animationConfig.animationParameter("laserOrigin")
  laser.destination = animationConfig.animationParameter("laserDestination")
  laser.color = animationConfig.animationParameter("altLaserColor") or animationConfig.animationParameter("laserColor")
  laser.width = animationConfig.animationParameter("altLaserWidth") or animationConfig.animationParameter("laserWidth") or 0.2

  if laser.origin and laser.destination then
    if primaryProjectileSpeed and aimAngle then
      drawTrajectory(laser.origin, aimAngle, primaryProjectileSpeed*1.3)
    else
      local laserLine = worldify(laser.origin, laser.destination)
      localAnimator.addDrawable({
          line = laserLine,
          width = laser.width,
          fullbright = true,
          color = laser.color
      }, "Player+1")
    end
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

function renderChargeBar(chargeTimer, chargeTime, overchargeTime,
  position, offset, barColor, length, width, borderwidth)

  local length = length or 2
  local barWidth = width or 1
  local borderwidth = borderwidth or 0.7
  local barColor = barColor or {75,75,75}
  local offset = offset or {0, -1.25}
  
  -- calculate bar stuff
  local base = vec2.add(position, offset)
  local base_a = vec2.add(base, {-length/2, 0}) -- start (left)
  local base_b = vec2.add(base, {length/2, 0})  -- end   (right)
  local a, b

  -- render border
  a = vec2.add(base_a, {-borderwidth/8, 0})
  b = vec2.add(base_b, {borderwidth/8, 0})
  local chargeBarBorder = worldify(a, b)
  localAnimator.addDrawable({
    line = chargeBarBorder,
    width = barWidth + borderwidth*2,
    fullbright = true,
    color = {0,0,0}
  }, "ForegroundEntity+1")

  local chargeLength = length * chargeTime / (chargeTime + overchargeTime)

  -- render chargetime bar
  local chargeTimeBar = worldify(base_a, vec2.add(base_a, {chargeLength, 0}))
  localAnimator.addDrawable({
    line = chargeTimeBar,
    width = barWidth,
    fullbright = true,
    color = barColor
  }, "ForegroundEntity+1")

  -- render overcharge time bar
  local overchargeTimeBar = worldify(vec2.add(base_a, {chargeLength, 0}), base_b)
  localAnimator.addDrawable({
    line = overchargeTimeBar,
    width = barWidth,
    fullbright = true,
    color = {255, 0, 0}
  }, "ForegroundEntity+1")

  -- render jamScore
  a = base_a
  b = vec2.add(base_a, {length * chargeTimer / (chargeTime + overchargeTime), 0})
  local jamScoreBar = {a, b}
  localAnimator.addDrawable({
    line = jamScoreBar,
    width = barWidth,
    fullbright = true,
    color = {255, 255, 0}
  }, "ForegroundEntity+1")

end

function brighten(color, brightness)
  local newColor = {0, 0, 0}
  for i, rgb in ipairs(color) do
    newColor[i] = math.min(255, rgb * brightness)
  end
  return newColor
end


-- test
function drawTrajectory(muzzlePos, angle, speed, steps, renderTime, color)
  local lineColor = color or {255, 255, 255, 128}
  local gravity = world.gravity(activeItemAnimation.ownerPosition())
  local renderTime = renderTime or 3
  local stepTime = renderTime / (steps or 50)
  local vorig = muzzlePos
  local vo = muzzlePos
  local timeElapsed = 0
  while timeElapsed < renderTime do
    
    timeElapsed  = timeElapsed + stepTime

    local vi = {
      vorig[1] + (speed * math.cos(angle) * timeElapsed),
      vorig[2] + (speed * math.sin(angle) * timeElapsed) - (gravity * timeElapsed ^ 2) / 2
    }

    local collision = world.lineTileCollisionPoint(vo, vi)
    
    if collision then
      vi = collision[1]
    end

    localAnimator.addDrawable({
      line = {vo, vi},
      width = 0.2,
      fullbright = true,
      color = lineColor
    }, "ForegroundEntity+1")

    if collision then break end

    vo = vi
    
  end
end