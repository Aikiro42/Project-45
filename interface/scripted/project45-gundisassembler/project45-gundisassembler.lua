---@diagnostic disable: lowercase-global
require "/scripts/util.lua"
require "/scripts/project45/project45disassemble.lua"

project45disassemble = disassemble

function init()

end

function update(dt)
  local input = widget.itemGridItems("itemGrid")
  if #input > 1 then
    
  end
end


function disassemble()
  
  local input = widget.itemGridItems("itemGrid")[1]
  
  if not input then return end

  local output = project45disassemble(input)
  
  if not output then return end
  
  player.giveItem(output)
  world.sendEntityMessage(pane.containerEntityId(), "project45-clearGunDisassemblySlot")
  
end