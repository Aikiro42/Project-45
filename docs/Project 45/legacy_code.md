# `/items/active/weapons/ranged/abilities/project45gunfire/project45gunfireanimation.lua`
```lua

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
  local stockAmmoOffset = vec2.add(offset, {0, 1})

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
      stockAmmoOffset = vec2.add(offset, {0, 1.5})
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

  renderStockAmmoNumber(stockAmmoOffset, reloading)

end

function renderStockAmmoNumber(offset, reloading)
  local stockAmmo = animationConfig.animationParameter("stockAmmo") or 0
  if stockAmmo <= 0 then return end
  localAnimator.spawnParticle({
    type = "text",
    text= "^shadow;" .. stockAmmo,
    color = {128,128,128},
    size = 0.5,
    fullbright = true,
    flippable = false,
    layer = "front"
  }, vec2.add(activeItemAnimation.ownerAimPosition(), offset))
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
  
  -- render text
  localAnimator.spawnParticle({
    type = "text",
    text= "^shadow;" .. rating,
    color = textColors[rating],
    size = textSize,
    fullbright = true,
    flippable = false,
    layer = "front"
  }, vec2.add(base_b, {0, textSize}))

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
    local a = {base_a[1] - 0.375, base_a[2] + 4*time/timeMax}
    local b = {base_a[1] + 0.375, base_a[2] + 4*time/timeMax}
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
  local base_l = {base[1] - 0.5, base[2]}
  local base_r = {base[1] + 0.5, base[2]}

  local chargeProgress = chargeTimer / (chargeTime + overchargeTime)
  local overchargeProgress = math.max(0, chargeTimer - chargeTime) / overchargeTime
  local isPerfectCharge = perfectChargeRange[1] <= overchargeProgress and overchargeProgress <= perfectChargeRange[2]

  local chargeHexColorFunction = function(chargeTimer, chargeTime, overchargeTime, isPerfectCharge, asHex)
    local color
    if chargeTimer < chargeTime then
      color = {75,75,150}
      return asHex and project45util.rgbToHex(color) or color
    end
    if isPerfectCharge then
      color = {164,81,196}
      return asHex and project45util.rgbToHex(color) or color
    end
    local chargeProgress = math.max(0, chargeTimer - chargeTime) / overchargeTime
    color = {
      255,
      math.max(0, math.floor(255 * (1 - chargeProgress))),
      0
    }
    return asHex and project45util.rgbToHex(color) or color
  end

  -- render base
  if isPerfectCharge then
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

  -- render bar
  if not accurateBars then
    localAnimator.addDrawable({
      image = "/items/active/weapons/ranged/abilities/project45gunfire/chargebar/project45-chargebar.png"
        -- .. string.format("?scale=%f;1", chargeProgress)
        .. string.format("?crop=0;0;%f;1", chargeProgress * 8)
        .. string.format("?setcolor=%s", chargeHexColorFunction(chargeTimer, chargeTime, overchargeTime, isPerfectCharge, true))
      ,position = {base[1] - 0.5 + math.floor(chargeProgress * 8) * 0.0625, base[2]},
      centered=true,
      fullbright = true,
    }, "Overlay")
  else
    local chargeEnd = {base_l[1] + chargeProgress, base_l[2]}
    localAnimator.addDrawable({
      line = worldify(base_l, chargeEnd),
      width = 1,
      fullbright = true,
      color = chargeHexColorFunction(chargeTimer, chargeTime, overchargeTime, isPerfectCharge)
    }, "Overlay")
  end

end

```