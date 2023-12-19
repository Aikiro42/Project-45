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
    if input.parameters.project45GunModInfo and input.parameters.isModded then

      if input.parameters.modSlots then
        for k, v in pairs(input.parameters.modSlots) do
          if k ~= "ability" then
            player.giveItem(v[2])
          end
        end
      end

      if input.parameters.statList then
        sb.logInfo(sb.printJson(input.parameters.statList))
        for k, v in pairs(input.parameters.statList) do
          if k ~= "wildcards" then
            player.giveItem({
              name = k,
              count = v})
          else
            for _, savedSeed in ipairs(v) do
              player.giveItem({
                name = "project45-wildcardstatmod",
                parameters = {
                  seed = savedSeed
                }})  
            end
          end
        end
      end
        
      player.giveItem(input.name)
      world.sendEntityMessage(pane.containerEntityId(), "project45-clearGunDisassemblySlot")
    end
  end
end