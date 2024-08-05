require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/project45neoweapon.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45Armadillo = WeaponAbility:new()

function Project45Armadillo:init()
  self.shieldRadius = self.shieldRadius or 3
  self.shieldOffset = self.shieldOffset or {0, -0.5}
  self.shieldActive = false

  self.cooldownTime = self.cooldownTime or 1
  self.cooldownTimer = self.cooldownTime

  self.riotShieldParameters = sb.jsonMerge({
    shieldPoly = {{0, -2}, {0, 2}},
    blockFailChance = 0.05,
    blockFailDuration = 0.1,
    perfectBlockDuration = 0.5,
    offset = {0, 0}
  }, self.riotShieldParameters)

  self.offsets = {
    base = config.getParameter("baseOffset", {0, 0}),
    underbarrel = config.getParameter("underbarrelOffset", {0, 0})
  }

  self.riotShieldParameters.offset = vec2.add(
    self.riotShieldParameters.offset,
    vec2.add(self.offsets.underbarrel, self.weapon.weaponOffset)
  )

  self.perfectBlockTimer = self.riotShieldParameters.perfectBlockDuration
  
  self.riotShieldDamageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.hitType == "ShieldHit" then
        if self.perfectBlockTimer > 0 then
          animator.playSound("break")
          animator.playSound("shockwave")
          world.spawnProjectile(
            "project45knightfallstasisshockwave",
            self:shieldPosition(),
            activeItem.ownerEntityId(),
            self:shieldAimVector(),
            true
          )
          self:flicker({"95D1F3FF", "60B8EAFF"}, 1)
          self.perfectBlockTimer = 0
        else
          animator.playSound("block")
          if self.blockFailTimer == 0
          and math.random() < self.riotShieldParameters.blockFailChance then
            self:flicker({"932625FF", "D93A3AFF"}, self.riotShieldParameters.blockFailDuration)
            animator.playSound("break")
            self.blockFailTimer = self.riotShieldParameters.blockFailDuration
            self.perfectBlockTimer = self.riotShieldParameters.perfectBlockDuration
            activeItem.setItemShieldPolys({})
          else
            self:flicker({"AF4E00FF", "EA9931FF"})
          end
        end
        return
      end
    end
  end)

  self.shiftHeldTimer = -1
  self.blockFailTimer = 0

  self.paired = activeItem.callOtherHandScript("isProject45Armadillo")
  self.disabled = self.disabled or (self.paired and activeItem.hand() == "primary")
  
  if not self.disabled then
    self:flicker({"AF4E00AA", "EA9931AA"}, self.riotShieldParameters.perfectBlockDuration, 0.5)
  else
    self:flicker({"FFFFFFAA", "FFFFFFAA"}, self.riotShieldParameters.perfectBlockDuration, 0.5)
  end

end

function Project45Armadillo:triggering()
  if self.shiftActivates then
    return self.shiftTriggered
  else
    return self.fireMode == (self.activatingFireMode or self.abilitySlot)
  end
end

function Project45Armadillo:updateShift(dt, shiftHeld)
  if not self.shiftActivates then return end
  if shiftHeld then
    if self.shiftHeldTimer < 0 then
      self.shiftHeldTimer = 0
    end
    self.shiftHeldTimer = self.shiftHeldTimer + dt
  elseif self.shiftHeldTimer >= 0 then
    if self.shiftHeldTimer <= self.shiftTime then
      self.shiftTriggered = true
    end
    self.shiftHeldTimer = -1
  end
end

function Project45Armadillo:update(dt, fireMode, shiftHeld)
    
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  
  self:updateRiotShield()

  if self.disabled then return end

  self:updateShift(dt, shiftHeld)

  if not self:triggering() then
    self.triggered = false
  end

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self:triggering() then
    self.shiftTriggered = false

    if not self.triggered
    and self.cooldownTimer == 0
    then
      self.cooldownTimer = self.cooldownTime
      if self:isShieldActive()
      then
        self:deactivateShield()
      elseif not status.resourceLocked("energy")
      then
        self:activateShield()
      end
      self.triggered = true
    end

  end

end

function Project45Armadillo:flicker(colors, time, intensity)
  intensity = intensity or 1
  time = time or 0.1
  if intensity <= 0 then
    return
  end
  self.flickerColors = colors
  self.flickerTime = time / intensity
  self.flickerTimer = time
end

function Project45Armadillo:updateRiotShield()

  self.blockFailTimer = math.max(0, self.blockFailTimer - self.dt)
  
  if self.flickerTimer > 0 and self.flickerTime > 0 then
    self.flickerTimer = self.flickerTimer - self.dt
    local flickerProgress = self.flickerTimer / self.flickerTime
    animator.setGlobalTag("shieldDirectives", string.format(
      "?scanlines=%s;%f;%s;%f",
      self.flickerColors[1],
      flickerProgress,
      self.flickerColors[2],
      flickerProgress
    ))
  end

  if self.blockFailTimer > 0 then
    activeItem.setItemShieldPolys({})
    return
  end

  if self.perfectBlockTimer == self.riotShieldParameters.perfectBlockDuration then
    animator.playSound("initShield")
    self:flicker({"AF4E0055", "EA993155"}, self.riotShieldParameters.perfectBlockDuration, 0.5)
  end

  self.perfectBlockTimer = math.max(0, self.perfectBlockTimer - self.dt)

  local shieldPoly = self.riotShieldParameters.shieldPoly
  shieldPoly = poly.translate(shieldPoly, self.riotShieldParameters.offset)
  shieldPoly = poly.rotate(shieldPoly, self.weapon.relativeWeaponRotation)
  activeItem.setItemShieldPolys({shieldPoly})

  self.riotShieldDamageListener:update()
end

function Project45Armadillo:isShieldActive()
  local statEffects = status.activeUniqueStatusEffectSummary()
  for _, effect in ipairs(statEffects) do
    if effect[1] == "project45armadilloeffect" then
      return true
    end
  end
  return false
end

function Project45Armadillo:activateShield()
  self:flicker({"E2C344FF", "A46E06FF"}, 0.5)
  status.addEphemeralEffect("project45armadilloeffect", status.resourceMax("energy")/(self.paired and 5 or 10), activeItem.ownerEntityId())
  status.overConsumeResource("energy", status.resourceMax("energy"))
  self.cooldownTimer = self.cooldownTime
end

function Project45Armadillo:deactivateShield()
  self:flicker({"E2C344FF", "A46E06FF"}, 0.5)
  status.removeEphemeralEffect("project45armadilloeffect")
end

-- Returns the muzzle of the gun
function Project45Armadillo:shieldPosition()
  return vec2.add(
    mcontroller.position(),
    activeItem.handPosition(
      vec2.rotate(
        self.riotShieldParameters.offset,
        self.weapon.relativeWeaponRotation
      )
    )
  )
end

function Project45Armadillo:shieldAimVector()
  local startPos = vec2.add(
    mcontroller.position(),
    activeItem.handPosition(
      vec2.rotate(
        vec2.add(self.riotShieldParameters.offset, {-1, 0}),
        self.weapon.relativeWeaponRotation
      )
    )
  )
  local endPos = self:shieldPosition()
  world.debugLine(startPos, endPos, "cyan")
  return vec2.norm(world.distance(endPos, startPos))
end

function Project45Armadillo:uninit()
end

function isProject45Armadillo()
  return true
end