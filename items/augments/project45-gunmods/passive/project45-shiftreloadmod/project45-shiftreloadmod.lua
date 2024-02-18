Passive = {}

function Passive:init()
  self.shiftReloadTimer = -1
  self.shiftReloadTime = self.shiftReloadTime or 0.3
end

function Passive:update(dt, fireMode, shiftheld)
  if shiftheld then
    if self.shiftReloadTimer < 0 then
      self.shiftReloadTimer = 0
    end
    self.shiftReloadTimer = self.shiftReloadTimer + self.dt
  elseif self.shiftReloadTimer >= 0 then
    if self.shiftReloadTimer < self.shiftReloadTime then

      if not self.weapon.currentAbility
      and not self.triggered
      and not self.isFiring
      then
  
          if status.resourcePositive("energy") and not status.resourceLocked("energy") then
              storage.reloadSignal = true
          else
              animator.playSound("shiftReloadError")
          end
  
          self.triggered = true
      else
          storage.reloadSignal = false
      end
      
    end
    self.shiftReloadTimer = -1
  end
end