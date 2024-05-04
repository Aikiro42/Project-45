require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"

project45deployment_initOld = init
project45deployment_updateOld = update

function debugStuff()
  
end

function init()
  project45deployment_initOld()

  self.debugTimer = 0
  self.toPrint = {}
  self.gunStatus = {}

  message.setHandler("updateProject45UI", function(messageName, isLocalEntity, statusKey, statusValue)
    self.gunStatus[statusKey] = statusValue
  end)

  message.setHandler("clearProject45UI", function(messageName, isLocalEntity)
    self.gunStatus = {}
  end)

  world.sendEntityMessage(entity.id(), "induceInitProject45UI")

end

function update(dt)
  project45deployment_updateOld(dt)

  if self.debugTimer <= 0 then
    self.debugTimer = 1
    debugStuff()
  else
    self.debugTimer = self.debugTimer - dt
  end

  -- DELETEME: random shit here

  
  if not wieldsProject45Weapon() then
    self.gunStatus = {}
  elseif not self.gunStatus.uiInitialized then
    world.sendEntityMessage(entity.id(), "induceInitProject45UI")
  end
  
  local ammoOffset = self.gunStatus.uiElementOffset or {0, 0}
  local isReloading = (self.gunStatus.reloadTimer or -1) >= 0
  local reloadProgress

  if isReloading then
    reloadProgress = (self.gunStatus.reloadTimer or 0) / (self.gunStatus.reloadTime or 1)
    ammoOffset = vec2.add(ammoOffset, self.gunStatus.uiElementOffset)
  end

  local currentAmmo = self.gunStatus.currentAmmo or 0
  renderStockAmmoCounter(
    self.gunStatus.uiPosition,
    vec2.add(ammoOffset, {0, 1}),
    self.gunStatus.stockAmmo or 0
  )
  renderAmmoCounter(
    self.gunStatus.uiPosition,
    ammoOffset,
    currentAmmo < 0 and "OK" or self.gunStatus.reloadRating or "BAD",
    currentAmmo,
    isReloading
  )
  renderChamberIndicator(
    self.gunStatus.uiPosition,
    vec2.add(ammoOffset, {0, -1}),
    self.gunStatus.chamberState
  )

  if isReloading then
    renderReloadRatingText(
      self.gunStatus.uiPosition,
      vec2.add(self.gunStatus.uiElementOffset, {0, 2.5}),
      self.gunStatus.reloadRating
    )
    if (self.modSettings or {}).accurateBars then
      renderReloadBars(
        self.gunStatus.uiPosition,
        self.gunStatus.uiElementOffset,
        self.gunStatus.reloadTimeframe,
        reloadProgress,
        self.gunStatus.reloadRating
      )
    else
      renderReloadBarImages(
        self.gunStatus.uiPosition,
        self.gunStatus.uiElementOffset,
        self.gunStatus.reloadTimeframe,
        reloadProgress,
        self.gunStatus.reloadRating
      )  
    end
  end
  --]]
  
end

function wieldsProject45Weapon()
  local primaryTags = set.new(player.primaryHandItemTags() or {})
  local altTags = set.new(player.altHandItemTags() or {})
  return primaryTags.project45 or altTags.project45
end

function renderAmmoCounter(uiPosition, offset, reloadRating, ammo, isReloading)

  local reloadRatingColors = {
    PERFECT = {255, 241, 191},
    GOOD = {191, 255, 255},
    OK = {255,255,255},
    BAD = {255, 127, 127}
  }

  if not uiPosition then return end
  ammo = ammo or 0
  offset = offset or {0, 0}

  if ammo < 0 then ammo = "E" end
  if isReloading then ammo = "R" end

  renderText(
    vec2.add(uiPosition, offset),
    tostring(ammo),
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

function renderChamberIndicator(uiPosition, offset, chamberState)
  if not uiPosition then return end
  offset = offset or {0, 0}
  chamberState = chamberState or "empty"
  localAnimator.addDrawable({
    image = "/scripts/project45/ui/chamber.png:" .. chamberState,
    position = vec2.add(uiPosition, offset),
    color = {255,255,255},
    fullbright = true,
  }, "ForegroundEntity+1")
end

function renderReloadRatingText(uiPosition, offset, reloadRating)
  if not uiPosition then return end

  local colors = {
    PERFECT = {255, 241, 191},
    GOOD = {191, 255, 255},
    OK = {255,255,255},
    BAD = {255, 127, 127}
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

function renderReloadBars(uiPosition, offset, reloadTimeframe, reloadProgress, reloadRating)
  if not uiPosition then return end
  if not reloadProgress then return end
  offset = offset or {0, 0}
  reloadRating = reloadRating or "OK"

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

end

function renderReloadBarImages(uiPosition, offset, reloadTimeframe, reloadProgress, reloadRating)
  if not uiPosition then return end
  if not reloadProgress then return end
  offset = offset or {0, 0}
  reloadRating = reloadRating or "OK"

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
    image = "/scripts/project45/ui/reloadbar.png:goodrange?multiply=" .. project45util.rgbToHex({106, 34, 132}) .. "FF?scalenearest=1;" .. goodScale,
    position = vec2.add(basePosition, {0, (-0.5 + goodY)*4}),
    color = {255,255,255},
    fullbright = true,
  }, "Overlay")

  -- perfect
  local perfectY = (reloadTimeframe[2] + reloadTimeframe[3]) / 2
  local perfectScale = reloadTimeframe[3] - reloadTimeframe[2]
  localAnimator.addDrawable({
    image = "/scripts/project45/ui/reloadbar.png:goodrange?multiply="
    .. project45util.rgbToHex({210, 156, 231})
    .. "FF?scalenearest=1;" .. perfectScale,
    position = vec2.add(basePosition, {0, (-0.5 + perfectY)*4}),
    color = {255,255,255},
    fullbright = true,
  }, "Overlay")

  -- arrow
  localAnimator.addDrawable({
    image = "/scripts/project45/ui/reloadbar-arrow.png",
    position = vec2.add(basePosition, {0, (-0.5 + reloadProgress)*4}),
    color = {255,255,255},
    fullbright = true,
  }, "Overlay")

end

function renderText(position, str, scale, doShadow, color, charSpacing)
  if not position then return end
  
  scale = scale or 1
  
  -- enable shadow by default
  if doShadow == nil then
    doShadow = true
  end
    
  local charWidth = 5 * scale
  charSpacing = (charSpacing or 0) *scale

  local textOffset = { charWidth/16 - (str:len() * (charWidth + charSpacing))/(2*8), 0}
  
  local leftPosition = vec2.add(position or {0, 0}, textOffset)
  
  for i=1, str:len() do
    local chr = string.upper(string.sub(str, i, i))
    if doShadow then-- shadow
      localAnimator.addDrawable({
        image = "/scripts/project45/ui/font.png:" .. chr,
        position = vec2.add(leftPosition, {0.05, -0.05}),
        transformation = {
          {scale, 0, 0},
          {0, scale, 0},
          {0, 0, 1}
        },
        color = {0,0,0},
        fullbright = true,
      }, "overlay")
    end
    
    -- text
    localAnimator.addDrawable({
      image = "/scripts/project45/ui/font.png:" .. chr,
      position = leftPosition,
      transformation = {
        {scale, 0, 0},
        {0, scale, 0},
        {0, 0, 1}
      },
      color = color,
      fullbright = true,
    }, "overlay")

    leftPosition = vec2.add(leftPosition, {(charWidth + charSpacing)/8, 0})
  end
end

