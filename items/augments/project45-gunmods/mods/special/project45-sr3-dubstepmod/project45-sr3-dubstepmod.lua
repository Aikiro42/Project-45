---@diagnostic disable: duplicate-set-field
require "/scripts/set.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"

Passive = Project45Passive:new()

function Passive:init()

  self._dubstepTimer = 0
  self._cueTimer = 0
  self._interval = self.passiveParameters.interval
  self._allowance = self.passiveParameters.allowance or 0.1
  self._measure = self.passiveParameters.measure or 4
  self._beat = false
  self._measureCount = 0

  animator.stopAllSounds("music")
  animator.playSound("music", -1)
  animator.setSoundVolume("music", 0.5)
  
  animator.setSoundVolume("fail", 2)
  animator.setSoundVolume("good", 1.125)

end

function Passive:update(dt, fireMode, shiftheld)
  if self._dubstepTimer < self._interval*self._measure then
    self._dubstepTimer = self._dubstepTimer + dt
  else
    self.beat = false
    self._measureCount = 0
  end
  self._cueTimer = self._cueTimer + dt
  if self._cueTimer >= self._interval then
    animator.playSound("beat")
    self._cueTimer = 0
  end
end

function Passive:onFire()
  local left = self._interval - self._allowance
  local right = self._interval + self._allowance
  
  if (self._dubstepTimer >= left
  and self._dubstepTimer < right)
  or not self._beat
  then
    animator.playSound("good")
    self._measureCount = self._measureCount + 1
    self._beat = true
  else
    animator.playSound("fail")
    self._beat = true
    self._measureCount = 0
  end
  if self._measureCount >= self._measure then
    -- buff
    world.spawnProjectile(
      "glitchexplosion",
      mcontroller.position(),
      player.id(),
      {1, 0},
      true,
      {
        power = 100
      }
    )
    status.addEphemeralEffect("rage", self._interval * (self._measure + 1))
    self._measureCount = 0
  end
  sb.logInfo(self._dubstepTimer - self._interval)
  self._cueTimer = 0
  self._dubstepTimer = 0
end

function Passive:onReloadStart()
  self._beat = false
  self._measureCount = 0
end
