Passive = {}

function Passive:init()
  self.shiftReloadTimer = -1
  self.shiftReloadTime = self.shiftReloadTime or 0.3

  self.bloodForBlood = 10
end

function Passive:update(dt, fireMode, shiftheld)

  if shiftheld then
    if self.weapon.isReloading then
      self.endReloadSignal = true
    else
      if self.shiftReloadTimer < 0 then
        self.shiftReloadTimer = 0
      end
      self.shiftReloadTimer = self.shiftReloadTimer + self.dt  
    end
  elseif self.shiftReloadTimer >= 0 then
    if self.shiftReloadTimer < self.shiftReloadTime then

      if not self.triggered
      -- and not self.weapon.currentAbility
      and (self.weapon.reloadTimer < 0 or self.weapon.isReloading)
      and not self.isFiring
      then
  
          if not status.resourceLocked("energy")
          or storage.stockAmmo + math.max(storage.project45GunState.ammo, 0) > 0 then              
            storage.reloadSignal = true
          else
              animator.playSound("shiftReloadError")
          end
  
      else
          storage.reloadSignal = false
      end
      
    end
    self.shiftReloadTimer = -1
  end

  if status.resourcePercentage("health") < 0.5 then
    status.addEphemeralEffect("rage")  
  end
end

function Passive:onFire()
  if status.resourcePercentage("health") > 0.1 then
    self.bloodForBlood = self.bloodForBlood - 1
  end
  if self.bloodForBlood <= 0 then
    self.bloodForBlood = 10
    status.modifyResourcePercentage("health", -0.05)
  end
end