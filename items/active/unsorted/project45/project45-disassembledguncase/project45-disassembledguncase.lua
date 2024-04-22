require "/scripts/vec2.lua"
require "/items/active/unsorted/rewardbag/rewardbag.lua"
require "/scripts/project45/project45util.lua"

local rewardBagInit = init

function init()
  rewardBagInit()
  self.disassembledItems = config.getParameter("disassembledItems", {})
  self.active = false
  storage.firing = false
end

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
    item.consume(1)
    sb.logInfo(sb.printJson(self.disassembledItems, 1))
    -- give item
    if player then
      local gun = config.getParameter("gunItem")
      if gun and self.disassembledItems then
        player.giveItem(gun)
        for _, item in pairs(self.disassembledItems) do
          player.giveItem(item)
        end
        
      else
        local gachaPools = {
          xssr = {2, "project45-gacha-xssr"},
          ssr = {2, "project45-gacha-ssr"},
          sr = {46, "project45-gacha-sr"},
          r = {50, "project45-gacha-r"}
        }
        local totalTickets = 0
        for _, gachaPool in pairs(gachaPools) do
          totalTickets = totalTickets + gachaPool[1]
        end
        local rng = math.random(0, totalTickets)
        local chosenPool = "xssr"
        for poolKey, gachaPool in pairs(gachaPools) do
          if rng < gachaPool[1] then
            chosenPool = poolKey
            break
          end
        end
        local treasure = root.createTreasure(self.gachaPools[chosenPool][2], 1, math.floor(math.random() * 2147483647))
        for _,item in pairs(treasure) do
          player.giveItem(item)
        end

      end
    end
    storage.firing = false
    return
  end
end

function activate(fireMode, shiftHeld)
  if not storage.firing then
    self.active = true
  end
end

function uninit()
end