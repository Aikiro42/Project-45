require "/scripts/augments/item.lua"
require "/scripts/util.lua"

function apply(input)

  if input.parameters then

    local savedGunSeed = input.parameters.seed
    local wasBought = input.parameters.bought  
    local savedUpgradeParameters = input.parameters.upgradeParameters

    if input.parameters.project45GunModInfo and input.parameters.isModded then

      local disassembledItems = {}

      if input.parameters.modSlots then
        for k, v in pairs(input.parameters.modSlots) do
          if k ~= "ability" then
            table.insert(disassembledItems, v[2])
          end
        end
      end

      if input.parameters.statList then
        for k, v in pairs(input.parameters.statList) do
          if k ~= "wildcards" then
            table.insert(disassembledItems, {
              name = k,
              count = v})
          else
            for _, savedSeed in ipairs(v) do
              table.insert(disassembledItems, {
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
        table.insert(disassembledItems, {
          name = "project45-ammostock",
          parameters = {
            ammo = stockAmmo + currentAmmo
          }})
      end

      local output = Item.new({name="project45-disassembledpouch", count=1, parameters={}})
      local gun = root.itemConfig(input)
      local gunConfig = gun.config

      output:setInstanceValue("gunItem", {name = input.name, parameters = {upgradeParameters = savedUpgradeParameters, seed = savedGunSeed, bought = wasBought}})
      output:setInstanceValue("shortdescription", gunConfig.shortdescription)
      output:setInstanceValue("rarity", gunConfig.rarity)
      output:setInstanceValue("disassembledItems", disassembledItems)

      output:setInstanceValue("description", string.format("Left-click to reobtain the gun and mods.\n^#96cbe7;Contains %d distinct items.^reset;", 1 + #disassembledItems))

      gun.config.tooltipFields.subtitle = "^#d93a3a;Disassembled Gun^reset;"
      gun.config.tooltipFields.objectImage = gun.directory .. gun.config.inventoryIcon
      output:setInstanceValue("tooltipFields", gun.config.tooltipFields)

      return output, config.getParameter("consume") == false and 0 or 1


    end
  end
end