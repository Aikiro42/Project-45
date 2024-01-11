Passive = {}

function Passive:init()
  self.bloodForBlood = 10
end

function Passive:update(dt, fireMode, shiftheld)
  if status.resourcePercentage("health") < 0.5 then
    status.addEphemeralEffect("rage")  
  end
end

function Passive:onFire()
  if status.resourcePercentage("health") > 0.1 then
    self.bloodForBlood = self.bloodForBlood - 1
  end
  if self.bloodForBlood <= 0 then
    self.bloodForBlood = 10
    status.modifyResourcePercentage("health", -0.05)
  end
end