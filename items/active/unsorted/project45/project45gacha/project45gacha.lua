require "/scripts/vec2.lua"
require "/items/active/unsorted/rewardbag/rewardbag.lua"
require "/scripts/project45/project45util.lua"

local rewardBagInit = init

function init()
  activeItem.setInstanceValue("isGachaItem", true)
  rewardBagInit()
  self.hardPity = config.getParameter("hardPity", 10)
  self.gachaPools = config.getParameter("gachaPools")
  storage.pity = storage.pity or config.getParameter("pity", 0)
  storage.pulls = storage.pulls or config.getParameter("pulls", 1)
  storage.guarantee = storage.guarantee or config.getParameter("guarantee", true)
  activeItem.setScriptedAnimationParameter("pullCounter", storage.pulls)
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

  if storage.pulls > 0
  and storage.firing and animator.animationState("firing") == "off" then
    
    storage.pulls = storage.pulls - 1
    activeItem.setScriptedAnimationParameter("pullCounter", storage.pulls)
    
    local chosenPool = ""

    if not storage.guarantee and storage.pity < self.hardPity then

      -- roll for pool
      local totalWeight = 0
      for gachaTier, pool in pairs(self.gachaPools) do
        totalWeight = totalWeight + pool[1]
      end
      local roll = math.ceil(math.random() * totalWeight)
      
      -- determine pull
      local currentWeight = 0
      for gachaTier, pool in pairs(self.gachaPools) do
        currentWeight = currentWeight + pool[1]
        if roll < currentWeight then
          chosenPool = gachaTier
          break
        end
      end

    else
      

      -- reset pity
      storage.pity = 0

      if storage.guarantee then
        -- guarantee
        chosenPool = "xssr"
        storage.guarantee = false
      else
        -- 50:50
        if math.random() <= 0.5 then
          chosenPool = "ssr"
          storage.guarantee = true
        else
          chosenPool = "xssr"
        end
      end

    end
    

    -- give item
    animator.playSound(chosenPool)
    if player then
      local treasure = root.createTreasure(self.gachaPools[chosenPool][2], 1, nil)
      for _,item in pairs(treasure) do
        player.giveItem(item)
      end
    end
    storage.pity = storage.pity + 1
    storage.firing = false
    return
  end
end


function activate(fireMode, shiftHeld)
  if not storage.firing and storage.pulls > 0 then
    self.active = true
  end
end

function uninit()
  activeItem.setInstanceValue("pity", storage.pity)
  activeItem.setInstanceValue("pulls", storage.pulls)
  activeItem.setInstanceValue("guarantee", storage.guarantee)
end