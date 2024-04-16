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
  local savedUpgradeParameters = input.parameters.upgradeParameters
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
                  seed = savedSeed
                }})
            end
          end
        end
      end

      local stockAmmo = (input.parameters.savedGunState or {stockAmmo = 0}).stockAmmo or 0
      local currentAmmo = math.max(0, (input.parameters.savedGunState or {ammo = 0}).ammo or 0)
      if stockAmmo + currentAmmo > 0 then
        local desc = string.format(
          "A box of surplus ammo. ^#e2c344;Contains %d rounds.^reset;\nApply on a weapon to stock up to ^#e2c344;6x its max ammo capacity^reset;.",
          stockAmmo + currentAmmo
        )
        player.giveItem({
          name = "project45-ammostock",
          parameters = {
            description = desc,
            ammo = stockAmmo + currentAmmo
          }})
      end
        
      player.giveItem({name = input.name, parameters = {upgradeParameters = savedUpgradeParameters, seed = savedGunSeed, bought = wasBought}})
      world.sendEntityMessage(pane.containerEntityId(), "project45-clearGunDisassemblySlot")
    end
  end
end