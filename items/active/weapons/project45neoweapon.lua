require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/weapon.lua"

local oldWeaponInit = Weapon.init
local oldWeaponUpdate = Weapon.update

function Weapon:init()

  self.recoilAmount = 0
  self.stanceProgress = 1

  -- self.weaponRotationCenter = {0, 0}
  
  self.relativeWeaponRotation = 0
  self.relativeArmRotation = 0

  self.baseArmRotation = 0
  self.baseWeaponRotation = 0

  self.armFrameAnimations = true

  self.stanceInterpolationMethod = "sin"

  oldWeaponInit(self)

  self.oldWeaponOffset = self.weaponOffset
  self.newWeaponOffset = self.weaponOffset
  self.oldWeaponRotationCenter = {0, 0}
  self.newWeaponRotationCenter = {0, 0}

end

function Weapon:update(dt, fireMode, shiftHeld)
  
  oldWeaponUpdate(self, dt, fireMode, shiftHeld)
  
  if self.stanceProgress < 1 then -- prevent from computing when unnecessary

    self.stanceProgress = math.min(1, self.stanceProgress + dt*(self.stanceTransitionSpeedMult or 4))

    if self.armAngularVelocity == 0 then
      self.baseArmRotation = interp[self.stanceInterpolationMethod](self.stanceProgress, self.oldArmRotation or 0, self.newArmRotation)
    end

    if self.weaponAngularVelocity == 0 then
      self.baseWeaponRotation = interp[self.stanceInterpolationMethod](self.stanceProgress, self.oldWeaponRotation or 0, self.newWeaponRotation)
    end

    self.weaponOffset = {
      interp[self.stanceInterpolationMethod](self.stanceProgress, self.oldWeaponOffset[1], self.newWeaponOffset[1]),
      interp[self.stanceInterpolationMethod](self.stanceProgress, self.oldWeaponOffset[2], self.newWeaponOffset[2])
    }

    self.relativeWeaponRotationCenter = {
      interp[self.stanceInterpolationMethod](self.stanceProgress, self.oldWeaponRotationCenter[1], self.newWeaponRotationCenter[1]),
      interp[self.stanceInterpolationMethod](self.stanceProgress, self.oldWeaponRotationCenter[2], self.newWeaponRotationCenter[2])
    }

    local weaponPosition = vec2.add(
      mcontroller.position(),
      activeItem.handPosition(
        self.weaponOffset
      )
    )

    world.debugPoint(vec2.add(weaponPosition, self.relativeWeaponRotationCenter), "blue")

  end
  
  self.relativeArmRotation = self.baseArmRotation + self.recoilAmount/2
  self.relativeWeaponRotation = self.baseWeaponRotation + self.recoilAmount/2
  
  if self.stance then
    self:updateAim()
    self.baseArmRotation = self.baseArmRotation + self.armAngularVelocity * dt
    self.baseWeaponRotation = self.baseWeaponRotation + self.weaponAngularVelocity * dt
  end

end

function Weapon:updateAim()
  for _,group in pairs(self.transformationGroups) do
    animator.resetTransformationGroup(group.name)
    animator.translateTransformationGroup(group.name, group.offset)
    animator.rotateTransformationGroup(group.name, group.rotation, group.rotationCenter)
    animator.translateTransformationGroup(group.name, self.weaponOffset)
    animator.rotateTransformationGroup(group.name, self.relativeWeaponRotation, self.relativeWeaponRotationCenter)
  end

  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.aimOffset, activeItem.ownerAimPosition())

  if self.stance.allowRotate then
    self.aimAngle = aimAngle
  elseif self.stance.aimAngle then
    self.aimAngle = self.stance.aimAngle
  end
  activeItem.setArmAngle(self.aimAngle + self.baseArmRotation + self.recoilAmount/2)

  local isPrimary = activeItem.hand() == "primary"
  if isPrimary then
    -- primary hand weapons should set their aim direction whenever they can be flipped,
    -- unless paired with an alt hand that CAN'T flip, in which case they should use that
    -- weapon's aim direction
    if self.stance.allowFlip then
      if activeItem.callOtherHandScript("dwDisallowFlip") then
        local altAimDirection = activeItem.callOtherHandScript("dwAimDirection")
        if altAimDirection then
          self.aimDirection = altAimDirection
        end
      else
        self.aimDirection = aimDirection
      end
    end
  elseif self.stance.allowFlip then
    -- alt hand weapons should be slaved to the primary whenever they can be flipped
    local primaryAimDirection = activeItem.callOtherHandScript("dwAimDirection")
    if primaryAimDirection then
      self.aimDirection = primaryAimDirection
    else
      self.aimDirection = aimDirection
    end
  end

  activeItem.setFacingDirection(self.aimDirection)

  if self.armFrameAnimations then
    activeItem.setFrontArmFrame(self.stance.frontArmFrame)
    activeItem.setBackArmFrame(self.stance.backArmFrame)
  end
end

function Weapon:setStance(stance)
  
  if not stance then return end
  if stance.disabled then return end
  if self.stance == stance then return end

  local snapWeapon = stance.snap or (self.weaponAngularVelocity and self.weaponAngularVelocity ~= 0)
  local snapArm = stance.snap or (self.armAngularVelocity and self.armAngularVelocity ~= 0)

  self.newWeaponRotation = util.toRadians(stance.weaponRotation or 0)
  self.newWeaponOffset = stance.weaponOffset or {0, 0}
  self.newWeaponRotationCenter = stance.weaponRotationCenter or {0, 0}
  self.newArmRotation = util.toRadians(stance.armRotation or 0)

  self.stanceInterpolationMethod = stance.interpolationMethod or "sin"
  
  -- snap if was rotating
  self.oldWeaponRotation = snapWeapon and self.newWeaponRotation or self.relativeWeaponRotation
  self.oldWeaponOffset = snapWeapon and self.newWeaponOffset or self.weaponOffset
  self.oldWeaponRotationCenter = snapWeapon and self.newWeaponRotationCenter or self.relativeWeaponRotationCenter
  self.oldArmRotation = snapArm and self.newArmRotation or self.relativeArmRotation
  
  self.stance = stance
  self.stanceTransitionSpeedMult = stance.transitionSpeedMult or 4
  self.weaponOffset = self.oldWeaponOffset

  
  self.armAngularVelocity = util.toRadians(stance.armAngularVelocity or 0)
  self.weaponAngularVelocity = util.toRadians(stance.weaponAngularVelocity or 0)

  if snapWeapon then
    self.oldWeaponRotation = self.newWeaponRotation
    self.baseWeaponRotation = self.newWeaponRotation
    self.relativeWeaponRotation = self.baseWeaponRotation + self.recoilAmount/2
  end

  if snapArm then
    self.oldArmRotation = self.newArmRotation
    self.baseArmRotation = self.newArmRotation
    self.relativeArmRotation = self.baseArmRotation + self.recoilAmount/2
  end

  for stateType, state in pairs(stance.animationStates or {}) do
    animator.setAnimationState(stateType, state)
  end

  for _, soundName in pairs(stance.playSounds or {}) do
    animator.playSound(soundName)
  end

  for _, particleEmitterName in pairs(stance.burstParticleEmitters or {}) do
    animator.burstParticleEmitter(particleEmitterName)
  end

  if self.armFrameAnimations then
    activeItem.setFrontArmFrame(self.stance.frontArmFrame)
    activeItem.setBackArmFrame(self.stance.backArmFrame)
  end
  activeItem.setTwoHandedGrip(stance.twoHanded or false)
  activeItem.setRecoil(stance.recoil == true)

  self.stanceProgress = stance.snap and 1 or 0

end

function getShiftAbility()
  local shiftAbilityConfig = config.getParameter("shiftAbility")
  if shiftAbilityConfig then
    return getAbility("shift", shiftAbilityConfig)
  end
end