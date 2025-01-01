require "/scripts/vec2.lua"
require "/scripts/status.lua"

Project45Challenger = WeaponAbility:new()

function Project45Challenger:init()
  self:loadState()
  self.killListener = damageListener("inflictedDamage", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId == activeItem.ownerEntityId()
      then
        -- bank currency based on enemy health lost x some multipliers
        local rewardedCurrency = 
              notification.healthLost
            * self.currencyPerHealthLost
            * self.currencyRewardMultiplier
            * (1 - storage.challengeMultiplier)
        storage.challengerRewardBank = storage.challengerRewardBank + rewardedCurrency
        sb.logInfo("Current Bank: " .. storage.challengerRewardBank)
        
        -- on kill or on reward threshold, reward banked currency
        -- chance to reward essence instead based on the challengeMultiplier
        if storage.challengerRewardBank > self.currencyRewardThreshold
        or notification.hitType == "Kill"
        then
          local droppedCurrency = math.floor(storage.challengerRewardBank)
          if droppedCurrency > 0 then  
            world.spawnItem(
              math.random() <= math.min(storage.challengeMultiplier, self.maxEssenceChance) and "essence" or "money",
              mcontroller.position(),
              droppedCurrency
            )
            storage.challengerRewardBank = storage.challengerRewardBank - droppedCurrency
          end
        end
      end
    end
  end)
end

function Project45Challenger:update(dt, fireMode, shiftHeld)
  if not self.canSetSettings and not storage.project45GunState.damageModifiers['challengerAbilityMult'] then
    storage.project45GunState.damageModifiers['challengerAbilityMult'] = {
      type = "mult",
      value= 0.8  -- force final 0.8x multiplier
    }
    storage.challengeMultiplier = 0.2
  end
  
  if storage.challengeMultiplier > self.challengerScalingThreshold then
    self.killListener:update()
  end
end

function Project45Challenger:uninit()
  self:saveState()
  if not self.canSetSettings then
    storage.project45GunState.damageModifiers['challengerAbilityMult'] = nil
    storage.challengeMultiplier = 0
  end
end

function Project45Challenger:saveState()
  activeItem.setInstanceValue("challengerBank", storage.challengerRewardBank)
end

function Project45Challenger:loadState()
  storage.challengerRewardBank = config.getParameter("challengerBank", 0)
  self.canSetSettings = (player and player.getProperty or status.statusProperty)("canSetSettings", false)
end
