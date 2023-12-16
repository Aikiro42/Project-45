require "/scripts/vec2.lua"
require "/items/active/unsorted/rewardbag/rewardbag.lua"
require "/scripts/project45/project45util.lua"

local rewardBagInit = init

function init()
  rewardBagInit()
  self.active = false
  storage.firing = false
  activeItem.setInstanceValue("isGachaItem", true)
  self.hardPity = config.getParameter("hardPity", 10)
  self.gachaPools = config.getParameter("gachaPools")
  storage.pity = storage.pity or config.getParameter("pity", 0)
  storage.pulls = storage.pulls or config.getParameter("pulls", 1)
  storage.guarantee = storage.guarantee or config.getParameter("guarantee", true)
  activeItem.setScriptedAnimationParameter("pullCounter", storage.pulls)
  for _, pool in ipairs({"r", "sr", "ssr", "xssr"}) do
    animator.setParticleEmitterActive(pool, false)    
  end
end

function update(dt, fireMode, shiftHeld)
  updateAim()

  storage.fireTimer = math.max(storage.fireTimer - dt, 0)

  if self.active then
    self.recoilRate = 0
    storage.chosenPool = storage.chosenPool or roll()
    animator.setParticleEmitterActive(storage.chosenPool, true)    
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
  and storage.firing and animator.animationState("firing") == "off" and storage.chosenPool then
    
    storage.pulls = storage.pulls - 1
    activeItem.setScriptedAnimationParameter("pullCounter", storage.pulls)
    local chosenPool = storage.chosenPool
    animator.setParticleEmitterActive(chosenPool, false)    
    storage.chosenPool = nil
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

function roll()

  if storage.pity < self.hardPity then

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
        
        if gachaTier == "ssr" or gachaTier == "xssr" then
          storage.pity = 0  -- reset pity on X/SSR

          if gachaTier == "ssr" then
            
            -- give or take guarantee
            storage.guarantee = not storage.guarantee
            
            -- if guarantee was set to false, give xssr; ssr otherwise
            return not storage.guarantee and "xssr" or "ssr"
          else -- gachaTier == "xssr"
            -- set guarantee to false
            storage.guarantee = false
            return "xssr"
          end
        end
        
        -- Non-SSR
        return gachaTier
      end
    end

  else

    storage.pity = 0

    if storage.guarantee then
      -- guarantee
      storage.guarantee = false
      return "xssr"
    else
      -- 50:50
      if math.random() <= 0.5 then
        storage.guarantee = true
        return "ssr"
      else
        return "xssr"
      end
    end

  end

  return "r"
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