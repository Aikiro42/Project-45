require "/scripts/vec2.lua"

Project45Tester = WeaponAbility:new()

function Project45Tester:init()
  activeItem.setScriptedAnimationParameter("testLaserOrigin", self.originPoint or mcontroller.position())
  activeItem.setScriptedAnimationParameter("testLaserDestination", activeItem.ownerAimPosition())
end

function Project45Tester:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  activeItem.setScriptedAnimationParameter("testLaserOrigin", self.originPoint or mcontroller.position())
  activeItem.setScriptedAnimationParameter("testLaserDestination", activeItem.ownerAimPosition())

  if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
    self.firing = false
  end

  if self.fireMode == "alt" and not self.firing then
    if self.originPoint then
      self.originPoint = nil
    else
      self.originPoint = activeItem.ownerAimPosition()
    end
    self.firing = true
  end


end

function Project45Tester:uninit()
end