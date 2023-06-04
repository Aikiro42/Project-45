require "/scripts/vec2.lua"
require "/scripts/util.lua"

local warningTriggered = false

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
end

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  synthethikmechanics_altUpdate()
  if not warningTriggered then
    warningTriggered = true
    -- sb.logInfo("[PROJECT 45] Obtained alt-ability animation update script.")
  end

  local hand = animationConfig.animationParameter("hand")
  local ammo = animationConfig.animationParameter("ammo") or "?"
  local reloadTimer = animationConfig.animationParameter("reloadTimer")
  local jamAmount = animationConfig.animationParameter("jamAmount", 0)
  local offset = reloadTimer < 0 and 0 or 2
  offset = offset + (jamAmount <= 0 and 0 or 2)
  offset = hand == "primary" and -offset or offset


  if ammo >= 0 then
    localAnimator.spawnParticle({
      type = "text",
      text= "^shadow;" .. ammo,
      color = {255, 255, 255},
      size = 1,
      fullbright = true,
      flippable = false,
      layer = "front"
    }, vec2.add(activeItemAnimation.ownerAimPosition(), {-2 + offset, 0}))

  else  -- TODO: show crossed-out mag instead of "E"
    localAnimator.spawnParticle({
      type = "text",
      text= "^shadow;E",
      color = {255, 255, 255},
      size = 1,
      fullbright = true,
      flippable = false,
      layer = "front"
    }, vec2.add(activeItemAnimation.ownerAimPosition(), {-2 + offset, 0}))
  end
  
  renderReloadBar()
  renderChargeBar()

end

function renderReloadBar(offset, barColor, length, width, borderwidth)
  
  local time = animationConfig.animationParameter("reloadTimer")
  
  if time < 0 then return end

  local timeMax = animationConfig.animationParameter("reloadTime")
  local quickReloadTimeframe = animationConfig.animationParameter("quickReloadTimeframe")
  local good = {quickReloadTimeframe[1], quickReloadTimeframe[4]}
  local perfect = {quickReloadTimeframe[2], quickReloadTimeframe[3]}
  local position = activeItemAnimation.ownerAimPosition()
  local offset = {-2, 0}

  local length = length or 4
  local barWidth = width or 2
  local borderwidth = borderwidth or 1
  local offset = offset or {-4, 0}
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


function renderChargeBar(position, offset, barColor, length, width, borderwidth)

  local chargeTimer = animationConfig.animationParameter("chargeTimer")

  if chargeTimer <= 0 then return end

  local chargeTime = animationConfig.animationParameter("chargeTime")
  local overchargeTime = animationConfig.animationParameter("overchargeTime")

  local position = activeItemAnimation.ownerAimPosition()
  local offset = offset or {0, -1.25}
  local barColor = barColor or {75,75,75}
  local length = length or 2
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