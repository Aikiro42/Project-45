Passive = {}

function Passive:init()
  self.shiftReloadTimer = -1
  self.shiftReloadTime = self.shiftReloadTime or 0.3
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
          or storage.project45GunState.stockAmmo + math.max(storage.project45GunState.ammo, 0) > 0 then              
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

  if storage.project45GunState.ammo == self.maxAmmo and storage.reloadRating == 4 then
    self.passiveDamageMult = 2
    self.recoilMomentum = 50
  else
    self.passiveDamageMult = 1
    self.recoilMomentum = 0
  end
end

function Passive:onFire()
  if storage.project45GunState.ammo == self.maxAmmo and storage.reloadRating == 4  then
    animator.playSound("firstFire")
  end
end