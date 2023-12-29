require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/poly.lua"
require "/scripts/actions/status.lua"
require "/scripts/project45/project45util.lua"

local warningTriggered, renderBarsAtCursor, runAnimUpdateScript, accurateBars
local messagesToRender = {}
local renderMessageTimer = 0
local prevReloadTimer = 0
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
  accurateBars = animationConfig.animationParameter("accurateBars")
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

  local barXOffset = (reloadTimer >= 0 and 2 or 0) + (jamAmount > 0 and 2 or 0)
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

function renderReloadBar(offset)
  
  local time = animationConfig.animationParameter("reloadTimer")
  
  if time < 0 then return end

  local timeMax = animationConfig.animationParameter("reloadTime")
  local quickReloadTimeframe = animationConfig.animationParameter("quickReloadTimeframe")
  local goodScale = quickReloadTimeframe[4] - quickReloadTimeframe[1]
  local perfectScale = quickReloadTimeframe[3] - quickReloadTimeframe[2]

  local position = renderBarsAtCursor and activeItemAnimation.ownerAimPosition() or activeItemAnimation.ownerPosition()
  local offset = offset or {-4, 0}
  offset[1] = (offset[1] < 0) and (offset[1] + 2) or (offset[1] - 2)
  local arrowLength = 0.4
  local textSize = 0.5

  local rating = animationConfig.animationParameter("reloadRating")
  
  local goodRangeColor = {106, 34, 132}
  local perfectRangeColor = {210, 156, 231}
  local textColors = {
    PERFECT = {255, 200, 0},
    GOOD = {150, 203, 231},
    OK = {255,255,255},
    BAD = {217, 58, 58}
  }

  local base = vec2.add(position, offset)
  local base_a = {base[1], base[2]-2} -- start (bottom)
  local base_b = {base[1], base[2]+2}  -- end   (top)
  local a, b, o
  
  -- render text
  o = vec2.add(base_b, {0, textSize})
  localAnimator.spawnParticle({
    type = "text",
    text= "^shadow;" .. rating,
    color = textColors[rating],
    size = textSize,
    fullbright = true,
    flippable = false,
    layer = "front"
  }, o)

  -- render bar image
  localAnimator.addDrawable({
    image = "/items/active/weapons/ranged/abilities/project45gunfire/reloadbar/project45-reloadbar-base.png" ..
      (rating == "PERFECT" and string.format("?border=1;%s50;FFFFFF00", project45util.rgbToHex({255, 200, 0})) or "")
    ,position = base,
    fullbright = true,
  }, "Overlay")

  if rating == "BAD" then
    -- render bar background if bad
    localAnimator.addDrawable({
      image = "/items/active/weapons/ranged/abilities/project45gunfire/reloadbar/project45-reloadbar.png:bad",
      position = base,
      fullbright = true,
    }, "Overlay")
  elseif rating == "GOOD" then
    localAnimator.addDrawable({
      image = "/items/active/weapons/ranged/abilities/project45gunfire/reloadbar/project45-reloadbar.png:good",
      position = base,
      fullbright = true,
    }, "Overlay")
  elseif rating == "PERFECT" then
    localAnimator.addDrawable({
      image = "/items/active/weapons/ranged/abilities/project45gunfire/reloadbar/project45-reloadbar.png:perfect",
      position = base,
      fullbright = true,
    }, "Overlay")
  end


  if animationConfig.animationParameter("performanceMode") and 
  prevReloadTimer - time == 0 then return end
  prevReloadTimer = time

  
  -- render arrow
  if not accurateBars then
    localAnimator.addDrawable({
      image = "/items/active/weapons/ranged/abilities/project45gunfire/reloadbar/project45-reloadbar-arrow.png",
      position = {base_a[1], base_a[2] + 4*time/timeMax},
      fullbright = true,
    }, "Overlay+1")

  else
    a = {base_a[1] - 0.25, base_a[2] + 4*time/timeMax}
    b = {base_a[1] + 0.25, base_a[2] + 4*time/timeMax}

    local arrow = worldify(a, b)
    localAnimator.addDrawable({
      line = arrow,
      width = 0.5,
      fullbright = true,
      color = {255, 0, 0}
    }, "Overlay+1")
  end
  
  -- render ranges
  if not accurateBars then

    -- render good range
    local mid = (quickReloadTimeframe[1] + quickReloadTimeframe[4])/2
    localAnimator.addDrawable({
      image = "/items/active/weapons/ranged/abilities/project45gunfire/reloadbar/project45-reloadbar.png:goodrange?scalenearest=1;"
      .. string.format("%f", goodScale)
      .. string.format("?setcolor=%s", project45util.rgbToHex(goodRangeColor))
      ,position = vec2.add(base, {0, (-0.5 + mid)*4}) ,
      fullbright = true,
    }, "Overlay")

    -- render perfect range
    mid = (quickReloadTimeframe[2] + quickReloadTimeframe[3])/2
    localAnimator.addDrawable({
      image = "/items/active/weapons/ranged/abilities/project45gunfire/reloadbar/project45-reloadbar.png:perfectrange?scalenearest=1;"
      .. string.format("%f", perfectScale)
      .. string.format("?setcolor=%s", project45util.rgbToHex(perfectRangeColor))
      ,position = vec2.add(base, {0, (-0.5 + mid)*4}),
      fullbright = true,
    }, "Overlay")

  else
    
    local rangeStart, rangeEnd
    
    -- render good range
    rangeStart = {base_a[1], base_a[2] + quickReloadTimeframe[1]*4}
    rangeEnd = {base_a[1], base_a[2] + quickReloadTimeframe[4]*4}
    localAnimator.addDrawable({
      line = worldify(rangeStart, rangeEnd),
      width = 2,
      fullbright = true,
      color = goodRangeColor
    }, "Overlay")

    -- render perfect range
    rangeStart = {base_a[1], base_a[2] + quickReloadTimeframe[2]*4}
    rangeEnd = {base_a[1], base_a[2] + quickReloadTimeframe[3]*4}
    localAnimator.addDrawable({
      line = worldify(rangeStart, rangeEnd),
      width = 2,
      fullbright = true,
      color = perfectRangeColor
    }, "Overlay")
  end

end

function renderJamBar(offset, barColor, length, width, borderwidth)
  local jamScore = animationConfig.animationParameter("jamAmount")
  if not jamScore or jamScore <= 0 then return end
  local position = renderBarsAtCursor and activeItemAnimation.ownerAimPosition() or activeItemAnimation.ownerPosition()
  local offset = offset or {-2, 0}
  offset[1] = (offset[1] < 0) and (offset[1] + 2) or (offset[1] - 2)
  
  -- calculate bar stuff
  local base = vec2.add(position, offset)

  -- render bar image
  localAnimator.addDrawable({
    image = "/items/active/weapons/ranged/abilities/project45gunfire/jambar/project45-jambar-base.png"
    ,position = base,
    fullbright = true,
  }, "Overlay")

  -- render jam score
  localAnimator.addDrawable({
    image = "/items/active/weapons/ranged/abilities/project45gunfire/jambar/project45-jambar.png?scale=1;"
      .. string.format("%f", jamScore)
    ,position = base,
    fullbright = true,
  }, "Overlay")

end


function renderChargeBar(offset, position, barColor, length, width, borderwidth)

  local chargeTimer = animationConfig.animationParameter("chargeTimer")

  if chargeTimer <= 0 then return end

  local chargeTime = animationConfig.animationParameter("chargeTime")
  local overchargeTime = animationConfig.animationParameter("overchargeTime")
  local perfectChargeRange = animationConfig.animationParameter("perfectChargeRange") or {-1, -1}

  local position = activeItemAnimation.ownerAimPosition()
  local offset = offset or {0, -1.5}
  
  -- calculate bar stuff
  local base = vec2.add(position, offset)

  local chargeProgress = chargeTimer / (chargeTime + overchargeTime)
  local overchargeProgress = math.max(0, chargeTimer - chargeTime) / overchargeTime

  local chargeHexColorFunction = function(chargeTimer, chargeTime, overchargeTime)
    if chargeTimer < chargeTime then
      return project45util.rgbToHex({128,128,128})
    end
    local chargeProgress = math.max(0, chargeTimer - chargeTime) / overchargeTime
    return project45util.rgbToHex({
      255,
      math.max(0, math.floor(255 * (1 - chargeProgress))),
      0
    })
  end

  if (perfectChargeRange[1] < overchargeProgress and overchargeProgress < perfectChargeRange[2]) then
    localAnimator.addDrawable({
      image = "/items/active/weapons/ranged/abilities/project45gunfire/chargebar/project45-chargebar-perfect.png"
      .. string.format("?multiply=FFFFFF%02X", math.floor(math.min(255, 1024*chargeProgress)))
      ,position = base,
      fullbright = true,
    }, "Overlay") 
  else
    localAnimator.addDrawable({
      image = "/items/active/weapons/ranged/abilities/project45gunfire/chargebar/project45-chargebar-base.png"
      .. string.format("?multiply=FFFFFF%02X", math.floor(math.min(255, 1024*chargeProgress)))
      ,position = base,
      fullbright = true,
    }, "Overlay") 
  end

  localAnimator.addDrawable({
    image = "/items/active/weapons/ranged/abilities/project45gunfire/chargebar/project45-chargebar.png"
      .. string.format("?crop=0;0;%f;1", chargeProgress * 8)
      .. string.format("?setcolor=%s", chargeHexColorFunction(chargeTimer, chargeTime, overchargeTime))
    ,position = base,
    fullbright = true,
  }, "Overlay")

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