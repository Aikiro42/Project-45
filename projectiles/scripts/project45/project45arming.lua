local oldInit = init or function() end
local oldUpdate = update or function(dt) end
local oldUninit = uninit or function() end

function init()
  oldInit()
  self.armingParameters = sb.jsonMerge({
    armingDistance = 10,
    actionOnReap = {},
    actionOnArmedReap = {}
  }, config.getParameter("armingParameters", {}))
  self.origin = mcontroller.position()
end

function update(dt) 
  oldUpdate()
  -- TESTME: self.currentPos = mcontroller.position()
end

function uninit()
  local actions
  if world.magnitude(mcontroller.position(), self.origin) > self.armingParameters.armingDistance then
    actions = self.armingParameters.actionOnArmedReap
  else
    actions = self.armingParameters.actionOnReap
  end
  for _, action in ipairs(actions) do
    projectile.processAction(action)
  end
end