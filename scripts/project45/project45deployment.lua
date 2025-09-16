require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"
require "/scripts/project45/project45animator.lua"

project45deployment_initOld = init
project45deployment_updateOld = update

function debugStuff()
  
end

function init()
  project45deployment_initOld()
  self.project45UiConfig = root.assetJson("/configs/project45/project45_general.config:uiConfig")
  self.debugTimer = 0
  self.toPrint = {}
  self.gunStatusL = {}
  self.gunStatusR = {}
  self.gunInfoL = {}
  self.gunInfoR = {}
  self.animatorL = Project45Animator:new(2)
  self.animatorR = Project45Animator:new(2)

  message.setHandler("updateProject45UIFieldL", function(messageName, isLocalEntity, statusKey, statusValue)
    self.gunStatusL[statusKey] = statusValue
  end)
  message.setHandler("updateProject45UIFieldR", function(messageName, isLocalEntity, statusKey, statusValue)
    self.gunStatusR[statusKey] = statusValue
  end)

  message.setHandler("initProject45UIL", function(messageName, isLocalEntity, gunInfo)
    self.gunInfoL = gunInfo
  end)

  message.setHandler("initProject45UIR", function(messageName, isLocalEntity, gunInfo)
    self.gunInfoR = gunInfo
  end)

  message.setHandler("updateProject45UIL", function(messageName, isLocalEntity, gunStatus, reset)
    self.gunStatusL = sb.jsonMerge(self.gunStatusL or {}, gunStatus)
  end)
  message.setHandler("updateProject45UIR", function(messageName, isLocalEntity, gunStatus, reset)
    self.gunStatusR = sb.jsonMerge(self.gunStatusR or {}, gunStatus)
  end)

  message.setHandler("resetProject45UIL", function()
    self.gunStatusL = {}
  end)
  message.setHandler("resetProject45UIR", function()
    self.gunStatusR = {}
  end)

end

function update(dt)

  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  
  project45deployment_updateOld(dt)

  if self.debugTimer <= 0 then
    self.debugTimer = 1
    debugStuff()
  else
    self.debugTimer = self.debugTimer - dt
  end

  -- DELETEME: random shit here

  renderSide(dt, "L")
  renderSide(dt, "R")
end

function renderSide(dt, side)
  
  if not wieldsProject45Weapon(side) then
    self["gunStatus" .. side] = {}
    self["gunInfo" .. side] = {}
    return
  end
  
  local performanceMode = (self["gunInfo" .. side].modSettings or {}).performanceMode
  local ammoOffset = self["gunInfo" .. side].uiElementOffset or {0, 0}
  local isReloading = (self["gunStatus" .. side].reloadTimer or -1) >= 0
  local jamAmount = self["gunStatus" .. side].jamAmount or 0
  local reloadProgress

  if (isReloading or jamAmount > 0) then
    if (self["gunInfo" .. side].modSettings or {}).renderBarsAtCursor then
      ammoOffset = vec2.add(ammoOffset, self["gunInfo" .. side].uiElementOffset)
    end
    if isReloading then
      reloadProgress = (self["gunStatus" .. side].reloadTimer or 0) / (self["gunInfo" .. side].reloadTime or 1)
    end
  end

  if not performanceMode then
    self["animator" .. side]:update(dt)
  end

  local currentAmmo = self["gunStatus" .. side].currentAmmo or 0
  renderStockAmmoCounter(
    self["gunStatus" .. side].aimPosition,
    vec2.add(ammoOffset, {0, 1}),
    self["gunStatus" .. side].stockAmmo or 0
  )

  renderAmmoCounter(
    self["gunStatus" .. side].aimPosition,
    ammoOffset,
    currentAmmo < 0 and "OK" or self["gunStatus" .. side].reloadRating or "BAD",
    currentAmmo,
    isReloading,
    side
  )

  if not performanceMode then
    renderChamberIndicator(
      self["gunStatus" .. side].aimPosition,
      vec2.add(ammoOffset, {0, -1}),
      self["gunStatus" .. side].chamberState,
      self["gunInfo" .. side].chamberIndicatorSprite
    )
  end

  renderChargeBar(
    self["gunStatus" .. side].aimPosition,
    vec2.add(ammoOffset, {0, performanceMode and -1 or -1.75}),
    self["gunInfo" .. side].chargeTime,
    self["gunInfo" .. side].overchargeTime,
    self["gunInfo" .. side].perfectChargeRange,
    self["gunStatus" .. side].chargeTimer
  )

  if isReloading then
    if not (self["gunInfo" .. side].modSettings or {}).performanceMode then
      renderReloadRatingText(
        self["gunStatus" .. side].uiPosition,
        vec2.add(self["gunInfo" .. side].uiElementOffset, {0, 2.5}),
        self["gunStatus" .. side].reloadRating
      )
    end
    renderReloadBar(
      self["gunStatus" .. side].uiPosition,
      self["gunInfo" .. side].uiElementOffset,
      self["gunInfo" .. side].reloadTimeframe,
      reloadProgress,
      self["gunStatus" .. side].reloadRating
    )
  elseif jamAmount > 0 then
    renderJamBar(
      self["gunStatus" .. side].uiPosition,
      self["gunInfo" .. side].uiElementOffset,
      jamAmount
    )
  end
  --]]
  
end

function wieldsProject45Weapon(side)
  local tags = side == "L" and set.new(player.primaryHandItemTags() or {}) or set.new(player.altHandItemTags() or {})
  return tags.project45
end

function renderAmmoCounter(uiPosition, offset, reloadRating, ammo, isReloading, side)

  local reloadRatingColors = {
    PERFECT = {255, 241, 191},
    GOOD = {191, 255, 255},
    OK = {255,255,255},
    BAD = {255, 127, 127}
  }

  if not uiPosition then return end
  ammo = ammo or 0
  offset = offset or {0, 0}

  local ammoCounterImageScale = 0.75
  local displayedAmmo = ammo

  if ammo < 0 then
    if self["gunInfo" .. side].modSettings.useAmmoCounterImages then
      self["animator" .. side]:render(
        {
          image="/scripts/project45/ui/reloadindicator.png:empty.<frame>",
          position = vec2.add(uiPosition, offset),
          color = {255,255,255},
          transformation = {
            {ammoCounterImageScale, 0, 0},
            {0, ammoCounterImageScale, 0},
            {0, 0, 1}
          },
          fullbright = true
        },
        2, "Overlay"
      )
      displayedAmmo = ""
    else
      displayedAmmo = "E"
    end
  end

  if isReloading and ammo <= 0 then
    if self["gunInfo" .. side].modSettings.useAmmoCounterImages then
      self["animator" .. side]:render(
        {
          image="/scripts/project45/ui/reloadindicator.png:reloading.<frame>",
          position = vec2.add(uiPosition, offset),
          color = {255,255,255},
          transformation = {
            {ammoCounterImageScale, 0, 0},
            {0, ammoCounterImageScale, 0},
            {0, 0, 1}
          },
          fullbright = true
        },
        2, "Overlay"
      )
      displayedAmmo = ""
    else
      displayedAmmo = "R"
    end
  end
  
  renderText(
    vec2.add(uiPosition, offset),
    displayedAmmo,
    1.125,
    true,
    reloadRatingColors[reloadRating or "BAD"],
    -0.5
  )

end

function renderStockAmmoCounter(uiPosition, offset, stockAmmo)
  if not uiPosition then return end
  offset = offset or {0, 1}
  if stockAmmo <= 0 then return end
  renderText(
    vec2.add(uiPosition, offset),
    tostring(stockAmmo),
    0.8,
    true,
    {100, 100, 100},
    -0.5
  )
end

function renderChamberIndicator(uiPosition, offset, chamberState, chamberIndicatorSprite)
  chamberIndicatorSprite = chamberIndicatorSprite or "/scripts/project45/ui/chamber-ballistic.png"
  if not uiPosition then return end
  if not chamberState then return end

  if not set.new({"ready", "filled", "empty"})[chamberState] then
    renderText(
      vec2.add(uiPosition, offset),
      chamberState,
      0.8,
      true,
      {255,255,255},
      -0.5
    )
    return
  end

  offset = offset or {0, 0}
  localAnimator.addDrawable({
    image = chamberIndicatorSprite .. ":" .. chamberState,
    position = vec2.add(uiPosition, offset),
    color = {255,255,255},
    fullbright = true,
  }, "ForegroundEntity+1")
end

function renderReloadRatingText(uiPosition, offset, reloadRating)
  if not uiPosition then return end

  local colors = {
    PERFECT = {255, 200, 0},
    GOOD = {150, 203, 231},
    OK = {255,255,255},
    BAD = {217, 58, 58}
  }

  renderText(
    vec2.add(uiPosition, offset),
    reloadRating,
    0.75,
    true,
    colors[reloadRating],
    -0.5
  )
end

function renderReloadBar(uiPosition, offset, reloadTimeframe, reloadProgress, reloadRating)
  if not uiPosition then return end
  if not reloadProgress then return end
  offset = offset or {0, 0}
  reloadRating = reloadRating or "OK"

  local zoneColors = {
    bad = {255,255,255},
    good = {106, 34, 132},
    perfect = {210, 156, 231}
  }

  local zoneComplements = {
    bad = {200, 0, 0},
    good = {149,209,243},
    perfect={255, 200, 0}
  }

  local basePosition = vec2.add(uiPosition, offset)
  
  reloadTimeframe = reloadTimeframe or {0.5, 0.6, 0.7, 0.8}
  local perfectReloadTimeframe = {reloadTimeframe[2], reloadTimeframe[3]}
  
  -- base
  localAnimator.addDrawable({
    image = "/scripts/project45/ui/reloadbar-base.png",
    position = basePosition,
    color = {255,255,255},
    fullbright = true,
  }, "Overlay")

  -- rating
  if reloadRating ~= "OK" then
    localAnimator.addDrawable({
      image = "/scripts/project45/ui/reloadbar.png:" .. reloadRating,
      position = basePosition,
      color = {255,255,255},
      fullbright = true,
    }, "Overlay")
  end

  -- good
  local goodY = (reloadTimeframe[1] + reloadTimeframe[4]) / 2
  local goodScale = reloadTimeframe[4] - reloadTimeframe[1]
  localAnimator.addDrawable({
    image = "/scripts/project45/ui/reloadbar.png:goodrange",
    position = vec2.add(basePosition, {0, (-0.5 + goodY)*4}),
    color = zoneColors.good,
    transformation = {
      {1, 0, 0},
      {0, goodScale, 0},
      {0, 0, 1}
    },
    fullbright = true,
  }, "Overlay")

  -- perfect
  local perfectY = (reloadTimeframe[2] + reloadTimeframe[3]) / 2
  local perfectScale = reloadTimeframe[3] - reloadTimeframe[2]
  localAnimator.addDrawable({
    image = "/scripts/project45/ui/reloadbar.png:perfectrange",
    -- .. string.format("?multiply=%sFF", project45util.rgbToHex({210, 156, 231})),
    position = vec2.add(basePosition, {0, (-0.5 + perfectY)*4}),
    color = zoneColors.perfect,
    transformation = {
      {1, 0, 0},
      {0, perfectScale, 0},
      {0, 0, 1}
    },
    fullbright = true,
  }, "Overlay")


  local currentZone = "bad"
  
  if reloadTimeframe[2] <= reloadProgress and reloadProgress <= reloadTimeframe[3] then
    currentZone = "perfect"
  elseif reloadTimeframe[1] <= reloadProgress and reloadProgress <= reloadTimeframe[4] then
    currentZone = "good"
  end
  -- sb.logInfo(reloadProgress)

  -- arrow
  localAnimator.addDrawable({
    image = self.project45UiConfig.reloadArrow.image,
    position = vec2.add(basePosition, {0, (-0.5 + reloadProgress)*4}),
    color = zoneComplements[currentZone] or project45util.complement(zoneColors[currentZone]),
    transformation = {
      {self.project45UiConfig.reloadArrow.scale, 0, 0},
      {0, self.project45UiConfig.reloadArrow.scale, 0},
      {0 ,0 ,1}
    },
    fullbright = true,
  }, "Overlay")

end

function renderJamBar(uiPosition, offset, jamAmount)
  if not uiPosition then return end
  jamAmount = jamAmount or 0
  if jamAmount <= 0 then return end
  
  -- base
  localAnimator.addDrawable({
    image = "/scripts/project45/ui/jambar-base.png",
    position = vec2.add(uiPosition, offset),
    color = {255,255,255},
    fullbright = true,
  }, "Overlay")

  -- bar
  localAnimator.addDrawable({
    image = "/scripts/project45/ui/jambar.png",
    position = vec2.add(uiPosition, offset),
    color = {255,255,255},
    transformation = {
      {1, 0, 0},
      {0, jamAmount, 0},
      {0, 0, 1}
    },
    fullbright = true,
  }, "Overlay")
  
end

function renderChargeBar(uiPosition, offset, chargeTime, overchargeTime, perfectChargeRange, chargeTimer)
  if not uiPosition then return end
  if not chargeTimer then return end
  if chargeTimer <= 0 then return end
  chargeTime = chargeTime or 0
  overchargeTime = overchargeTime or 0
  if chargeTime + overchargeTime <= 0 then return end
  perfectChargeRange = perfectChargeRange or {-1, -1}

  local fadeMult = 32
  -- colors

  local chargingColor = {0,0,0}
  local chargedColor = {255,255,0}

  local perfectChargeColor = {255, 128, 0}
  local overchargeColor = {255, 0, 0}
  local perfectOverchargeColor = {128, 0, 255}

  local perfectChargeRangeColor = {0, 255, 255}

  local overallProgress = util.clamp(fadeMult * chargeTimer / (chargeTime + overchargeTime), 0, 1)
  
  local overchargeProgress = overchargeTime <= 0 and 0 or util.clamp((chargeTimer - chargeTime) / overchargeTime, 0, 1)
  local isPerfectCharge = perfectChargeRange[1] <= overchargeProgress and overchargeProgress <= perfectChargeRange[2]

  local basePosition = vec2.add(uiPosition, offset)
  
  -- base
  localAnimator.addDrawable({
    image = isPerfectCharge
    and "/scripts/project45/ui/chargebar-perfect.png"
    or "/scripts/project45/ui/chargebar-base.png"
    .. string.format("?multiply=FFFFFF%02X", math.ceil(255*overallProgress)),
    position = basePosition,
    color = {255,255,255},
    fullbright = true,
  }, "Overlay")

  -- charge bar
  local chargeProgress = chargeTime <= 0 and 1 or math.min(1, chargeTimer/chargeTime)
  local chargeColor = project45util.gradient(chargingColor, chargedColor, chargeProgress)
  local chargeBarPosition = vec2.add(basePosition, {-0.5 + chargeProgress/2, 0})
  localAnimator.addDrawable({
    image = "/scripts/project45/ui/chargebar.png"
    .. string.format("?multiply=FFFFFF%02X", math.ceil(255*overallProgress)),
    position = chargeBarPosition,
    transformation = {
      {chargeProgress, 0, 0},
      {0, 1, 0},
      {0, 0, 1},
    },
    color = isPerfectCharge and perfectChargeColor or chargeColor,
    fullbright = true,
  }, "Overlay")

  -- overcharge bar
  if overchargeTime > 0 then

    if overchargeProgress > 0 and perfectChargeRange[1] >= 0 and perfectChargeRange[2] > 0 then
      localAnimator.addDrawable({
        image = "/scripts/project45/ui/chargebar.png"
        .. string.format("?multiply=FFFFFF%02X", math.ceil(255*overallProgress)),
        position = vec2.add(basePosition, {-0.5 + (perfectChargeRange[1] + perfectChargeRange[2])/2 , 0}),
        transformation = {
          {perfectChargeRange[2] - perfectChargeRange[1], 0, 0},
          {0, 1, 0},
          {0, 0, 1},
        },
        color = perfectChargeRangeColor,
        fullbright = true,
      }, "Overlay")  
    end

    local overchargeBarPosition = vec2.add(basePosition, {-0.5 + overchargeProgress/2, 0})
    localAnimator.addDrawable({
      image = "/scripts/project45/ui/chargebar.png"
      .. string.format("?multiply=FFFFFF%02X", math.ceil(255*overallProgress)),
      position = overchargeBarPosition,
      transformation = {
        {overchargeProgress, 0, 0},
        {0, 1, 0},
        {0, 0, 1},
      },
      color = isPerfectCharge and perfectOverchargeColor or overchargeColor,
      fullbright = true,
    }, "Overlay")
  end

  
end

function renderText(position, str, scale, doShadow, color, charSpacing)
  if not position then return end
  if not str then return end
  if type(str) ~= "string" then
    str = tostring(str)
  end
  
  scale = scale or 1
  
  local finalScale = scale * self.project45UiConfig.font.scaleFactor

  -- enable shadow by default
  if doShadow == nil then
    doShadow = true
  end
    
  local charWidth = self.project45UiConfig.font.charWidth * finalScale
  charSpacing = (charSpacing or 0) * finalScale * self.project45UiConfig.font.spacingFactor

  local textOffset = { charWidth/16 - (str:len() * (charWidth + charSpacing))/(2*8), 0}
  
  local leftPosition = vec2.add(position or {0, 0}, textOffset)
  
  for i=1, str:len() do
    local chr = string.upper(string.sub(str, i, i))
    if doShadow then-- shadow
      localAnimator.addDrawable({
        image = self.project45UiConfig.font.spritePath .. ":" .. chr,
        position = vec2.add(leftPosition, {0.05, -0.05}),
        transformation = {
          {finalScale, 0, 0},
          {0, finalScale, 0},
          {0, 0, 1}
        },
        color = {0,0,0},
        fullbright = true,
      }, "overlay")
    end
    
    -- text
    localAnimator.addDrawable({
      image = self.project45UiConfig.font.spritePath .. ":" .. chr,
      position = leftPosition,
      transformation = {
        {finalScale, 0, 0},
        {0, finalScale, 0},
        {0, 0, 1}
      },
      color = color,
      fullbright = true,
    }, "overlay")

    leftPosition = vec2.add(leftPosition, {(charWidth + charSpacing)/8, 0})
  end
end

