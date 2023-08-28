require "/scripts/vec2.lua"

Project45FlashLaser = WeaponAbility:new()

local OFF, FLASH, LASER, FLASHLASER = 1, 2, 3, 4

function Project45FlashLaser:init()
  self:reset()
  self.flashLaserStates = {"off", "flash", "laser", "flashlaser"}

  -- this ability allows straight lasers by default.
  -- if the primary ability is project45gunfire, and the laser is enabled, then
  --[[
  local primaryAbility = config.getParameter("primaryAbility", {})
  local projectileType = primaryAbility.projectileType
  if projectileType then
    projectileType = type(projectileType) == "table" and projectileType[1] or projectileType
    local projectileConfig = util.mergeTable(root.projectileConfig(projectileType), self.projectileParameters)
    local projSpeed = projectileConfig.speed or 50
    
    if root.projectileGravityMultiplier(projectileType) ~= 0 then
      activeItem.setScriptedAnimationParameter("primaryLaserArcSteps", self.laser.trajectoryConfig.renderSteps)
      activeItem.setScriptedAnimationParameter("primaryLaserArcSpeed", projSpeed)
      activeItem.setScriptedAnimationParameter("primaryLaserArcRenderTime", projectileConfig.timeToLive)
      activeItem.setScriptedAnimationParameter("primaryLaserArcGravMult", root.projectileGravityMultiplier(projectileType))
    end
  end
  --]]

end

function Project45FlashLaser:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  -- render laser
  if (storage.state == FLASHLASER or storage.state == LASER) and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    local scanOrig = self:firePosition()
    local range = world.magnitude(scanOrig, activeItem.ownerAimPosition())
    local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(), self.laserRange))
    scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest
    activeItem.setScriptedAnimationParameter("altLaserEnabled", true)
    activeItem.setScriptedAnimationParameter("altLaserStart", scanOrig)
    activeItem.setScriptedAnimationParameter("altLaserEnd", scanDest)
  elseif world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    activeItem.setScriptedAnimationParameter("altLaserEnabled", false)
    activeItem.setScriptedAnimationParameter("altLaserStart", nil)
    activeItem.setScriptedAnimationParameter("altLaserEnd", nil)
  end

  if self.fireMode == "alt" and self.lastFireMode ~= "alt" then
    storage.state = (storage.state % 4) + 1
    animator.setAnimationState("project45flashlaser", self.flashLaserStates[storage.state])
    if storage.state == FLASH or storage.state == FLASHLASER then
      animator.setLightActive("flashlight", true)
      animator.setLightActive("flashlightSpread", true)
      animator.playSound("flashlight")
    else
      animator.setLightActive("flashlight", false)
      animator.setLightActive("flashlightSpread", false)
    end
        
    if not (storage.state == FLASHLASER or storage.state == LASER) then
      activeItem.setScriptedAnimationParameter("altLaserStart", nil)
      activeItem.setScriptedAnimationParameter("altLaserEnd", nil)
      activeItem.setScriptedAnimationParameter("altLaserColor", nil)
      activeItem.setScriptedAnimationParameter("altLaserWidth", nil)
    else
      activeItem.setScriptedAnimationParameter("altLaserColor", self.laserColor)
      activeItem.setScriptedAnimationParameter("altLaserWidth", self.laserWidth)
      animator.playSound("laser")
    end

  end
  self.lastFireMode = fireMode
end

function Project45FlashLaser:reset()
  storage.state = storage.state or OFF
  if storage.state == FLASH or storage.state == FLASHLASER then
    animator.setLightActive("flashlight", true)
    animator.setLightActive("flashlightSpread", true)
    animator.playSound("flashlight")
  else
    animator.setLightActive("flashlight", false)
    animator.setLightActive("flashlightSpread", false)
  end
end

function Project45FlashLaser:uninit()
  self:reset()
end

function Project45FlashLaser:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(self.weapon.muzzleOffset, self.weapon.relativeWeaponRotation)))
end

function Project45FlashLaser:aimVector()
  local firePos = self:firePosition()
  local basePos =  vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate({0, self.weapon.muzzleOffset[2]}, self.weapon.relativeWeaponRotation)))
  world.debugPoint(firePos, "cyan")
  world.debugPoint(basePos, "cyan")
  local aimVector = vec2.norm(world.distance(firePos, basePos))
  aimVector = vec2.rotate(aimVector, sb.nrand((inaccuracy or 0), 0))
  return aimVector
end