require "/scripts/vec2.lua"
require "/scripts/util.lua"

-- Code pulled from Starforge.

function init()
  self.guiConfig = config.getParameter("guiConfig")
  object.setInteractive(true)
end

function onInteraction(args)
  return {"ScriptPane", self.guiConfig}
end