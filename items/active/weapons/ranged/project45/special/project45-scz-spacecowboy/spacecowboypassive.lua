Passive = {}

function Passive:update(dt, fireMode, shiftheld)
  if storage.ammo == self.maxAmmo and storage.reloadRating == 4 then
    self.passiveDamageMult = 2
    self.recoilMomentum = 50
  else
    self.passiveDamageMult = 1
    self.recoilMomentum = 0
  end
end

function Passive:onFire()
  if storage.ammo == self.maxAmmo and storage.reloadRating == 4  then
    animator.playSound("firstFire")
  end
end