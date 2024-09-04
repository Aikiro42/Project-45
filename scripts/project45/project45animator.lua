require "/scripts/versioningutils.lua"
Project45Animator = {}

function Project45Animator:new(animationRate)
  self.frame = 1
  self.animationRate = animationRate or 1
  self.frameTimer = 0
  self.frames = 1
  return self
end

function Project45Animator:update(dt)
  if self.frameTimer >= 1 then
    self.frameTimer = 0
    self.frame = (self.frame % self.frames) + 1
  else
    self.frameTimer = self.frameTimer + (dt * self.animationRate)
  end
end

function Project45Animator:render(drawable, frames, layer)
  self.frames = frames or self.frames
  replacePatternInData(drawable, "image", "<frame>", self.frame)
  localAnimator.addDrawable(drawable, layer or "Overlay")
end