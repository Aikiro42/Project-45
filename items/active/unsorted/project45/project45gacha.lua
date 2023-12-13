require "/scripts/vec2.lua"
require "/items/active/unsorted/rewardbag/rewardbag.lua"
require "/scripts/project45/project45util.lua"

function update(dt, fireMode, shiftHeld)
  updateAim()

  storage.fireTimer = math.max(storage.fireTimer - dt, 0)

  if self.active then
    self.recoilRate = 0
  else
    self.recoilRate = math.max(1, self.recoilRate + (10 * dt))
  end
  self.recoil = math.max(self.recoil - dt * self.recoilRate, 0)

  if self.active and not storage.firing and storage.fireTimer <= 0 then
    self.recoil = math.pi/2 - self.aimAngle
    activeItem.setArmAngle(math.pi/2)
    if animator.animationState("firing") == "off" then
      animator.setAnimationState("firing", "fire")
    end
    storage.fireTimer = config.getParameter("fireTime", 1.0)
    storage.firing = true

  end

  self.active = false

  if storage.firing and animator.animationState("firing") == "off" then

    local odds = config.getParameter("odds")
    local chosenPool = ""
    local roll = math.floor(math.random() * 100)
    for _, odd in ipairs(odds) do
      if roll < odd[2] then
        chosenPool = odd[1]
        break
      end
    end
    sb.logInfo(chosenPool)
    animator.playSound(chosenPool)
    item.consume(1)
    if player then
      local level = 1
      local treasure = root.createTreasure(chosenPool, level, nil)
      for _,item in pairs(treasure) do
        player.giveItem(item)
      end
    end
    storage.firing = false
    return
  end
end