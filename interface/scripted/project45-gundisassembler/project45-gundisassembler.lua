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
  local savedGunSeed = input.parameters.seed
  local wasBought = input.parameters.bought
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
                  seed = savedSeed,
                  bought = wasBought
                }})  
            end
          end
        end
      end
        
      player.giveItem({name = input.name, parameters = {seed = savedGunSeed}})
      world.sendEntityMessage(pane.containerEntityId(), "project45-clearGunDisassemblySlot")
    end
  end
end