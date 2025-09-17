old_init = init or function() end
old_update = update or function() end

dt = 1/60

function init()

  old_init()

  self.animationStates = {
    starting = {
      frames = 5,
      cycle = 0.1,
      mode = "transition",
      transition = "idle"
    },
    idle = {
      frames = 4,
      cycle = 0.1,
      mode = "loop"
    }
  }
  self.currentState = "starting"
  self.currentFrame = 1
  self.currentFrameTimer = 0

end
function update()

  localAnimator.clearDrawables()
  localAnimator.clearLightSources()

  old_update()

  local flamePosition = animationConfig.animationParameter("flamePosition", activeItemAnimation.ownerPosition())
  local renderFlame = animationConfig.animationParameter("renderFlame")

  if renderFlame then

    local currentAnimationState = self.animationStates[self.currentState]

    self.currentFrameTimer = self.currentFrameTimer + dt
    if self.currentFrameTimer > currentAnimationState.cycle then
      if self.currentFrame == currentAnimationState.frames and currentAnimationState.mode == "transition" then
        self.currentState = currentAnimationState.transition
        currentAnimationState = self.animationStates[self.currentState]
      end
      self.currentFrameTimer = 0
      self.currentFrame = (self.currentFrame % currentAnimationState.frames) + 1
    end

    local frameString = string.format("%s.%d", self.currentState, self.currentFrame)
    
    localAnimator.addDrawable({
        image="/items/active/weapons/ranged/project45/project45-neo-pyroclast/project45-neo-pyroclast-flame.png:".. frameString,
        position=flamePosition,
        rotation=0,
        fullbright=true,
        centered=true
    }, "Player-1")
  
  else
    self.currentState = "starting"
    self.currentFrame = 1
    self.currentFrameTimer = 0
  end


end