require "/scripts/util.lua"


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
    if input.parameters then
        if input.parameters.acceptsGunMods and input.parameters.isModded then
    
            if input.parameters.modSlots then
              for k, v in pairs(input.parameters.modSlots) do
                if k ~= "ability" then
                  player.giveItem(v[2])
                end
              end
            end

            if input.parameters.statList then
                for k, v in pairs(input.parameters.statList) do
                    player.giveItem({
                      name = k,
                      count = v})
                end
            end
            
            player.giveItem(input.name)
            world.sendEntityMessage(pane.containerEntityId(), "project45-clearGunDisassemblySlot")
          end
    end
end