require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/poly.lua"
require "/scripts/actions/status.lua"
require "/scripts/project45/project45util.lua"

local warningTriggered, renderBarsAtCursor, runAnimUpdateScript, accurateBars
local messagesToRender = {nil}
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
  messagesToRender = animationConfig.animationParameter("project45GunFireMessages", {nil})
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


  --[[
                                crosshair
                                    |
                                    v
      ammo [jam bar] [reload bar] ( + ) [reload bar] [jam bar] ammo
  [charge bar]                                             [charge bar]
  --]]

  --[[
  local hand = animationConfig.animationParameter("hand")
  local reloadTimer = animationConfig.animationParameter("reloadTimer")
  local jamAmount = animationConfig.animationParameter("jamAmount", 0)

  local barXOffset = (reloadTimer >= 0 and 2 or 0) + (jamAmount > 0 and 2 or 0)
  local horizontalOffset = 2
  horizontalOffset = horizontalOffset + (renderBarsAtCursor and barXOffset or 0)
  horizontalOffset = hand == "primary" and -horizontalOffset or horizontalOffset
  barXOffset = hand == "primary" and -barXOffset or barXOffset

  renderAmmoNumber({horizontalOffset, 0}, reloadTimer >= 0)
  renderChamberIndicator({horizontalOffset, 0})
  renderReloadBar({horizontalOffset + (renderBarsAtCursor and 0 or barXOffset), 0})
  renderJamBar({horizontalOffset + (renderBarsAtCursor and 0 or barXOffset), 0})
  renderChargeBar({horizontalOffset, animationConfig.animationParameter("performanceMode") and -1 or -1.75})
  --]]
  
  renderLaser()
  renderHitscanTrails()
  renderBeam()
  renderBeamChain()

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

  local bezierParameters = animationConfig.animationParameter("primaryLaserBezierParameters")
  if bezierParameters then
    local bezierCurve = project45util.drawBezierCurve(
        bezierParameters.segments or 8,
        laserStart,
        laserEnd,
        animationConfig.animationParameter("primaryLaserBezierControlPoint", laserEnd)
      )
    for _, line in ipairs(bezierCurve) do
      local laserLine = worldify(line[1], line[2])
      localAnimator.addDrawable({
        line = laserLine,
        width = laserWidth,
        fullbright = true,
        color = laserColor
      }, "Player-2")
    end
  else
    local laserLine = worldify(laserStart, laserEnd)
    localAnimator.addDrawable({
      line = laserLine,
      width = laserWidth,
      fullbright = true,
      color = laserColor
    }, "Player-2")
  end


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
      if projectile.vfxCurve then
        for i, segment in ipairs(projectile.vfxCurve) do

          -- fucking algebra

          local n = #projectile.vfxCurve
          local wmax = (projectile.width or 1)

          local Tn = projectile.maxLifetime
          local tn = projectile.lifetime

          local Ti = Tn * (n - i) * util.clamp(projectile.vfxDecay or 0.5, 0, 1) / n
          
          local x = tn
          local mi = wmax / (Tn - Ti)
          local y = mi * (x - Ti)
          
          -- local segmentLifetime = projectile.lifetime / projectile.maxLifetime

          local bulletLine = worldify(segment[1], segment[2])
          localAnimator.addDrawable({
            line = bulletLine,
            width = math.max(0, y),
            fullbright = true,
            color = projectile.color or {0, 0, 0}
          }, "Player-1")
        end
      else
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
end

function renderBeamChain()
  local beamChain = animationConfig.animationParameter("beamChain", {nil})
  local beamFuzz = animationConfig.animationParameter("beamFuzz", 0.5)
  
  if not beamChain then return end
  if #beamChain < 2 then return end

  local beamChainColor = animationConfig.animationParameter("beamChainColor", {255,0,255})
  local beamChainWidth = animationConfig.animationParameter("beamChainWidth", 2)
  local beamChainInnerWidth = animationConfig.animationParameter("beamChainInnerWidth", 1)
  for i=2,#beamChain do
    local segment = worldify(beamChain[i-1], beamChain[i])
    localAnimator.addDrawable({
      line = segment,
      width = beamChainWidth + sb.nrand(beamFuzz, 0),
      fullbright = true,
      color = beamChainColor
    }, "Player-1")
    localAnimator.addDrawable({
      line = segment,
      width = beamChainInnerWidth + sb.nrand(beamFuzz, 0),
      fullbright = true,
      color = {255,255,255}
    }, "Player-1")

    -- collision light
    localAnimator.addLightSource({
      position = beamChain[i],
      color = beamChainColor,
      pointLight = true,
      pointBeam = 0,
    })

    -- collision impact sparks
    localAnimator.spawnParticle(
      "project45beamendsmoke",
      beamChain[i+1]
    )
    for i = 1, 3 do
      localAnimator.spawnParticle(
        "project45beamendspark",
        beamChain[i+1]
      )
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
    local segment = worldify(circlePoly[i], circlePoly[i+1])
    localAnimator.addDrawable({
      line = segment,
      width = circleWidth,
      fullbright = true,
      color = circleColor
    }, "ForegroundEntity+1")
    i = i + 1
  end
end