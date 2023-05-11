require "/scripts/vec2.lua"
require "/scripts/util.lua"

function update()
    
    localAnimator.clearDrawables()
    localAnimator.clearLightSources()

    local aimPos = activeItemAnimation.ownerAimPosition()
    local grenadeIndicatorOffset = animationConfig.animationParameter("grenadeIndicatorOffset")
    local trajectoryIndicatorColor = animationConfig.animationParameter("trajectoryIndicatorColor")
    local grenadeLauncherState = animationConfig.animationParameter("grenadeLauncherState")
    local warning = animationConfig.animationParameter("grenadeLauncherChargeWarning")

    local aimAngle = animationConfig.animationParameter("altAimAngle") or 0
    local muzzlePos = animationConfig.animationParameter("altMuzzlePos") or {0, 0}
    local worldGravity = animationConfig.animationParameter("altWorldGravity") or 0
    local projSpeed = animationConfig.animationParameter("altProjectileSpeed") or 1

    localAnimator.addDrawable({
        image = "/items/active/weapons/ranged/abilities/project45grenadelauncher/project45grenadelauncherindicator.png:" .. grenadeLauncherState,
        position = vec2.add(aimPos, grenadeIndicatorOffset),
        color = {255,255,255},
        fullbright = true,
      }, "ForegroundEntity+1")

    if warning then
      localAnimator.addDrawable({
        image = "/items/active/weapons/ranged/abilities/project45grenadelauncher/project45grenadelauncherwarning.png",
        position = vec2.add(aimPos, grenadeIndicatorOffset),
        color = {255,255,255},
        fullbright = true,
      }, "ForegroundEntity+2")
      drawTrajectory(muzzlePos, aimAngle, projSpeed*1.3, 10, 1, trajectoryIndicatorColor)
    end


end


-- test
function drawTrajectory(muzzlePos, angle, speed, steps, renderTime, color)
  local lineColor = color or {255, 255, 255, 128}
  muzzlePos = muzzlePos or activeItemAnimation.ownerAimPosition()
  local gravity = world.gravity(activeItemAnimation.ownerPosition())
  speed = speed or 25
  local stepTime = renderTime / steps
  renderTime = renderTime or 10
  local vorig = muzzlePos
  local vo = muzzlePos
  local timeElapsed = 0
  while timeElapsed < renderTime do
    
    timeElapsed  = timeElapsed + stepTime

    local vi = {
      vorig[1] + (speed * math.cos(angle) * timeElapsed),
      vorig[2] + (speed * math.sin(angle) * timeElapsed) - (gravity * timeElapsed ^ 2) / 2
    }

    local collision = world.lineTileCollisionPoint(vo, vi)
    
    if collision then
      vi = collision[1]
    end

    localAnimator.addDrawable({
      line = {vo, vi},
      width = 0.5,
      fullbright = true,
      color = lineColor
    }, "ForegroundEntity+1")

    if collision then break end

    vo = vi
    
  end
end