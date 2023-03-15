require "/scripts/vec2.lua"
require "/scripts/util.lua"

-- Code pulled from Starforge.

function init()
  object.setInteractive(true)
	message.setHandler("project45-clearGunDisassemblySlot", removeItem)
end


function update(dt)
end

function removeItem()
  world.containerTakeAll(entity.id())
end