require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/poly.lua"
require "/scripts/project45/project45util.lua"

local warningTriggered = false
local messagesToRender = {}
local renderMessageTimer = 0
local renderBarsAtCursor = false
local runAnimUpdateScript = false
local animTable = {
  ammo = {
    ticks = 15,
    ticker = 0,
    frames = 2,
    frame = 1
  }
}

synthethikmechanics_altInit = init or function()
  if not warningTriggered then
    warningTriggered = true
    -- sb.logInfo("[PROJECT 45] (" .. animationConfig.animationParameter("shortDescription") .. ") Failed to get alt-ability animation script update function. Weapon may be one-handed, not have an alt-ability, or may not have an alt-ability animation script.")
  end
end

synthethikmechanics_altUpdate = update or function()
    if not warningTriggered then
      warningTriggered = true
      -- sb.logInfo("[PROJECT 45] (" .. animationConfig.animationParameter("shortDescription") .. ") Failed to get alt-ability animation script update function. Weapon may be one-handed, not have an alt-ability, or may not have an alt-ability animation script.")
    end
  end

function init()
  synthethikmechanics_altInit()
  messagesToRender = animationConfig.animationParameter("project45GunFireMessages")
  renderBarsAtCursor = animationConfig.animationParameter("renderBarsAtCursor")
  runAnimUpdateScript = runAnimUpdateScript or animationConfig.animationParameter("useAmmoCounterImages")
end

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  synthethikmechanics_altUpdate()
  updateAnimTable()

  if not warningTriggered then
    warningTriggered = true
    -- sb.logInfo("[PROJECT 45] Obtained alt-ability animation update script.")
  end

  if #messagesToRender > 0 then
    renderMessageTimer = renderMessageTimer == 0 and renderMessages() or renderMessageTimer - 1
  end

  local hand = animationConfig.animationParameter("hand")
  local reloadTimer = animationConfig.animationParameter("reloadTimer")
  local jamAmount = animationConfig.animationParameter("jamAmount", 0)

  --[[
                                crosshair
                                    |
                                    v
      ammo [jam bar] [reload bar] ( + ) [reload bar] [jam bar] ammo
  [charge bar]                                             [charge bar]
  --]]

  local barXOffset = reloadTimer < 0 and 2 or 0
  barXOffset = barXOffset + jamAmount <= 0 and 2 or 0
  local horizontalOffset = 2
  horizontalOffset = horizontalOffset + (renderBarsAtCursor and barXOffset or 0)
  horizontalOffset = hand == "primary" and -horizontalOffset or horizontalOffset
  barXOffset = hand == "primary" and -barXOffset or barXOffset

  renderAmmoNumber({horizontalOffset, 0}, reloadTimer >= 0)

  renderChamberIndicator({horizontalOffset, 0})

  renderLaser()
  renderReloadBar({horizontalOffset + (renderBarsAtCursor and 0 or barXOffset), 0})
  renderJamBar({horizontalOffset + (renderBarsAtCursor and 0 or barXOffset), 0})
  renderChargeBar({horizontalOffset, animationConfig.animationParameter("performanceMode") and -1 or -1.625})
  renderHitscanTrails()
  renderBeam()

end

function updateAnimTable()
  if not runAnimUpdateScript then return end
  for anim, _ in pairs(animTable) do
    animTable[anim].ticker = animTable[anim].ticker + 1
    if animTable[anim].ticker > animTable[anim].ticks then
      animTable[anim].frame = (animTable[anim].frame % animTable[anim].frames) + 1
      animTable[anim].ticker = 0
    end
  end
end

function renderMessages(messageOffset)
  -- render incompat messages
  localAnimator.spawnParticle({
    type = "text",
    text= "^shadow;" .. messagesToRender[1],
    color = {255, 128, 128},
    size = 0.4,
    fullbright = true,
    flippable = false,
    layer = "front",
    timeToLive = 1,
    initialVelocity = {0, 2},
  }, vec2.add(activeItemAnimation.ownerPosition(), messageOffset or {0, 2}))
  table.remove(messagesToRender, 1)
  return math.floor(60 * 0.3)
end  

function renderAmmoNumber(offset, reloading)
  
  local reloadRatingTextColor = {
    PERFECT = {255, 241, 191},
    GOOD = {191, 255, 255},
    OK = {255,255,255},
    BAD = {255, 127, 127}
  }
  
  local ammo = animationConfig.animationParameter("ammo") or "?"
  local rating = animationConfig.animationParameter("reloadRating")
  local renderAmmoImage = animationConfig.animationParameter("useAmmoCounterImages")

  if ammo >= 0 then
    localAnimator.spawnParticle({
      type = "text",
      text= "^shadow;" .. ammo,
      color = rating and reloadRatingTextColor[rating] or {255,255,255},
      size = 1,
      fullbright = true,
      flippable = false,
      layer = "front"
    }, vec2.add(activeItemAnimation.ownerAimPosition(), offset))

  else
    if renderAmmoImage then
      if reloading then
        localAnimator.addDrawable({
          image = "/items/active/weapons/ranged/abilities/project45gunfire/reloadindicator.png:reloading." .. animTable.ammo.frame,
          position = vec2.add(vec2.add(activeItemAnimation.ownerAimPosition(), offset), {0, 0.25}),
          color = {255,255,255},
          fullbright = true,
        }, "overlay")
      else
        localAnimator.addDrawable({
          image = "/items/active/weapons/ranged/abilities/project45gunfire/reloadindicator.png:empty." .. animTable.ammo.frame,
          position = vec2.add(vec2.add(activeItemAnimation.ownerAimPosition(), offset), {0, 0.25}),
          color = {255,255,255},
          fullbright = true,
        }, "overlay")
      end
    else
      localAnimator.spawnParticle({
        type = "text",
        text= string.format("^shadow;%s", reloading and "R" or "E"),
        color = {255, 255, 255},
        size = 1,
        fullbright = true,
        flippable = false,
        layer = "front"
      }, vec2.add(activeItemAnimation.ownerAimPosition(), offset))
    end
  end
end

function renderChamberIndicator(offset)
  if animationConfig.animationParameter("performanceMode") then return end
  local chamberState = animationConfig.animationParameter("primaryChamberState")
  if not chamberState then return end

  local aimPosition = activeItemAnimation.ownerAimPosition()

  localAnimator.addDrawable({
    image = "/items/active/weapons/ranged/abilities/project45gunfire/chamberindicator.png:" .. chamberState,
    position = vec2.add(vec2.add(aimPosition, offset), {0, -1}),
    color = {255,255,255},
    fullbright = true,
  }, "ForegroundEntity+1")
end

function renderBezierTest()
  local pos = activeItemAnimation.ownerPosition()
  local aim = activeItemAnimation.ownerAimPosition()
  local mid = {(pos[1] + aim[1])/2, (pos[2] + aim[2])/2}
  local i = vec2.add(pos, {0, 0})
  local o = vec2.add(aim, {0, 0})
  
  local tfunc = function(a, b)
    local x = world.lineTileCollisionPoint(a, b)
    if x then
      return x[1]
    end
  end

  local c = vec2.add(mid, {sb.nrand(5, 0), sb.nrand(5, 0)})
  -- local c = vec2.add(mid, {0, 5})
  local curve = project45util.drawBezierCurve(10, i, o, c, tfunc)
  for _, line in ipairs(curve) do
    local laserLine = worldify(line[1], line[2])
    localAnimator.addDrawable({
      line = laserLine,
      width = 0.5,
      fullbright = true,
      color = {255,255,255}
    }, "Player+1")
  end
end

function renderLaser()

  if
  not (animationConfig.animationParameter("altLaserEnabled")
  or animationConfig.animationParameter("primaryLaserEnabled"))
  then return end

  local laserColor = animationConfig.animationParameter("altLaserColor")
    or animationConfig.animationParameter("primaryLaserColor")
    or {255, 50, 50, 128}

    
  local laserWidth = animationConfig.animationParameter("altLaserWidth")
    or animationConfig.animationParameter("primaryLaserWidth")
    or 0.5


  if animationConfig.animationParameter("isSummonedProjectile") then
    drawSummonArea(laserColor, laserWidth)
    return
  end

  local laserStart = animationConfig.animationParameter("altLaserStart")
    or animationConfig.animationParameter("primaryLaserStart")
    or activeItemAnimation.ownerAimPosition()
  
  local laserEnd = animationConfig.animationParameter("altLaserEnd")
    or animationConfig.animationParameter("primaryLaserEnd")
    or activeItemAnimation.ownerPosition()

  if animationConfig.animationParameter("primaryLaserArcGravMult") then
    drawTrajectory(
      laserStart,
      math.atan(laserEnd[2] - laserStart[2], laserEnd[1] - laserStart[1]),
      animationConfig.animationParameter("primaryLaserArcSpeed") or 10,
      animationConfig.animationParameter("primaryLaserArcSteps") or 50,
      animationConfig.animationParameter("primaryLaserArcRenderTime") or 3,
      laserColor,
      animationConfig.animationParameter("primaryLaserArcGravMult") or 1
    )
    return
  end

  local laserLine = worldify(laserStart, laserEnd)
  localAnimator.addDrawable({
    line = laserLine,
    width = laserWidth,
    fullbright = true,
    color = laserColor
  }, "Player-2")

end

function renderReloadBar(offset, barColor, length, width, borderwidth)
  
  local time = animationConfig.animationParameter("reloadTimer")
  
  if time < 0 then return end

  local timeMax = animationConfig.animationParameter("reloadTime")
  local quickReloadTimeframe = animationConfig.animationParameter("quickReloadTimeframe")
  local good = {quickReloadTimeframe[1], quickReloadTimeframe[4]}
  local perfect = {quickReloadTimeframe[2], quickReloadTimeframe[3]}
  local position = renderBarsAtCursor and activeItemAnimation.ownerAimPosition() or activeItemAnimation.ownerPosition()

  local length = length or 4
  local barWidth = width or 2
  local borderwidth = borderwidth or 1
  local offset = offset or {-4, 0}
  offset[1] = (offset[1] < 0) and (offset[1] + 2) or (offset[1] - 2)
  local arrowLength = 0.4
  local textSize = 0.5

  local rating = animationConfig.animationParameter("reloadRating")
  local barColor = rating == "PERFECT" and {255, 200, 0}
    or rating == "GOOD" and {0, 255, 255}
    or rating == "BAD" and {255, 0, 0}
    or barColor or {255,255,255}

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
  a = vec2.add(base_a, {0, good[1]*length})
  b = vec2.add(base_a, {0, good[2]*length})
  local goodRange = {a, b}
  localAnimator.addDrawable({
    line = goodRange,
    width = barWidth,
    fullbright = true,
    color = {143, 0, 255}
  }, "ForegroundEntity+1")

  -- render perfect range
  a = vec2.add(base_a, {0, perfect[1]*length})
  b = vec2.add(base_a, {0, perfect[2]*length})
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

function renderJamBar(offset, barColor, length, width, borderwidth)
  local jamScore = animationConfig.animationParameter("jamAmount")
  if not jamScore or jamScore <= 0 then return end
  local position = renderBarsAtCursor and activeItemAnimation.ownerAimPosition() or activeItemAnimation.ownerPosition()
  local offset = offset or {-2, 0}
  offset[1] = (offset[1] < 0) and (offset[1] + 2) or (offset[1] - 2)

  local barColor = barColor or {75,75,75}
  local length = length or 4
  local barWidth = width or 2
  local borderwidth = borderwidth or 1
  
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


function renderChargeBar(offset, position, barColor, length, width, borderwidth)

  local chargeTimer = animationConfig.animationParameter("chargeTimer")

  if chargeTimer <= 0 then return end

  local chargeTime = animationConfig.animationParameter("chargeTime")
  local overchargeTime = animationConfig.animationParameter("overchargeTime")
  local perfectChargeRange = animationConfig.animationParameter("perfectChargeRange")

  local position = activeItemAnimation.ownerAimPosition()
  local offset = offset or {0, -1.5}
  local barColor = barColor or {75,75,75}
  local length = length or 1
  local barWidth = width or 1
  local borderwidth = borderwidth or 0.7
  
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


  if perfectChargeRange then
    local overchargeLength = length * overchargeTime / (chargeTime + overchargeTime)
    local perfectChargeBase = vec2.add(base_a, {chargeLength, 0})
    local perfectChargeTimeBar = worldify(
      vec2.add(perfectChargeBase, {overchargeLength * perfectChargeRange[1], 0}),
      vec2.add(perfectChargeBase, {overchargeLength * perfectChargeRange[2], 0})
    )
    localAnimator.addDrawable({
      line = perfectChargeTimeBar,
      width = barWidth,
      fullbright = true,
      color = {255, 255, 255}
    }, "ForegroundEntity+1")
  end


  -- render charge progress
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

-- Calculates the line from pos1 to pos2
-- that allows `localAnimator.addDrawable()`
-- to render it correctly
function worldify(pos1, pos2)
    
  local playerPos = activeItemAnimation.ownerPosition()
  local worldLength = world.size()[1]
  local fucky = {false, true, true, false}
  
  -- L is the x-size of the world
  -- |0|--[1]--|--[2]--|L/2|--[3]--|--[4]--|L|
  -- there is fucky behavior in quadrants 2 and 3
  local pos1Quadrant = math.ceil(4*pos1[1]/worldLength)
  local playerPosQuadrant = math.ceil(4*playerPos[1]/worldLength)

  local ducky = fucky[pos1Quadrant] and fucky[playerPosQuadrant]
  local distance = world.distance(pos2, pos1)

  local sameWorldSide = (pos1Quadrant > 2) == (playerPosQuadrant > 2)
    
  if ducky then
      if (
          (sameWorldSide and (pos1Quadrant > 2))
          or (pos1Quadrant < playerPosQuadrant)
      ) then
          pos1[1] =  pos1[1] - worldLength
      end
  else
      if pos1[1] > worldLength/2 then
          pos1[1] = pos1[1] - worldLength
      end
  end

  pos2 = vec2.add(pos1, distance)

  return {pos1, pos2}
end

function renderHitscanTrails()
  -- render hitscan trails
  local projectileStack = animationConfig.animationParameter("projectileStack")
  if not projectileStack then return end
  for i, projectile in ipairs(projectileStack) do
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
end

function renderBeam()
    -- worldify
    local beamLine = animationConfig.animationParameter("beamLine")
    if not beamLine then return end
    local beamWidth = animationConfig.animationParameter("beamWidth")
    local beamInnerWidth = animationConfig.animationParameter("beamInnerWidth")
    local beamColor = animationConfig.animationParameter("beamColor")

    beamLine = worldify(beamLine[1], beamLine[2])
    
    -- colored, outer beam
    localAnimator.addDrawable({
      line = beamLine,
      width = beamWidth,
      fullbright = true,
      color = beamColor or {255,255,255}
    }, "Player-1")
    -- lighter, inner beam
    localAnimator.addDrawable({
      line = beamLine,
      width = beamInnerWidth,
      fullbright = true,
      color = {255,255,255}
    }, "Player-1")

    -- collision light
    localAnimator.addLightSource({
      position = beamLine[2],
      color = beamColor,
      pointLight = true,
      pointBeam = 0,
    })

    -- collision impact sparks
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

-- test
function drawTrajectory(muzzlePos, angle, speed, steps, renderTime, color, gravMult)
  local lineColor = color or {255, 255, 255, 128}
  local gravity = world.gravity(activeItemAnimation.ownerPosition()) * (gravMult or 1)
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

    local arcSegment = worldify(vo, vi)
    localAnimator.addDrawable({
      line = arcSegment,
      width = 0.2,
      fullbright = true,
      color = lineColor
    }, "ForegroundEntity+1")

    if collision then break end

    vo = vi
    
  end
end

function drawSummonArea(color, width)

  local circlePoly = poly.translate(
    animationConfig.animationParameter("primarySummonArea") or {{0, 0}},
    activeItemAnimation.ownerAimPosition()
  )
  table.insert(circlePoly, circlePoly[1])
  local obstructed = animationConfig.animationParameter("muzzleObstructed")
  
  local circleColor = obstructed and {128, 128, 128, 128}
    or color
    or {0, 255, 255, 128}

  local circleWidth = width or 0.5
  
  local i = 1
  while i < #circlePoly do
    local segment = {circlePoly[i], circlePoly[i+1]}
    localAnimator.addDrawable({
      line = segment,
      width = circleWidth,
      fullbright = true,
      color = circleColor
    }, "ForegroundEntity+1")
    i = i + 1
  end
end