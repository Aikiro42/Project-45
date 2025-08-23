require "/scripts/augments/item.lua"
require "/scripts/util.lua"

-- @param input: ItemDescriptor
function disassemble(input)

  if input.parameters then

    local savedGunSeed = input.parameters.seed
    local wasBought = input.parameters.bought  
    local savedUpgradeParameters = input.parameters.upgradeParameters

    if input.parameters.project45GunModInfo and input.parameters.isModded then

      local disassembledItems = {}

      if input.parameters.modSlots then
        for k, v in pairs(input.parameters.modSlots) do
          local isAbility = {ability=true, shiftAbility=true}
          if not isAbility[k] then
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
            for wildcardItemId, savedAugmentConfigs in pairs(v) do
              for _, augmentConfig in ipairs(savedAugmentConfigs) do
                table.insert(disassembledItems, {
                  name = wildcardItemId,
                  parameters = {
                    augment = augmentConfig
                }})
              end
            end
          end
        end
      end

      local stockAmmo = (input.parameters.savedGunState or {stockAmmo = 0}).stockAmmo or 0
      if stockAmmo > 0 then
        table.insert(disassembledItems, {
          name = "project45-ammostock",
          parameters = {
            ammo = stockAmmo
          }})
      end

      local output = Item.new({name="project45-disassembledguncase", count=1, parameters={}})
      local gun = root.itemConfig(input)
      local gunConfig = gun.config

      output:setInstanceValue("gunItem", {name = input.name, parameters = {upgradeParameters = savedUpgradeParameters, seed = savedGunSeed, bought = wasBought}})
      output:setInstanceValue("shortdescription", gunConfig.shortdescription)
      output:setInstanceValue("rarity", gunConfig.rarity)
      output:setInstanceValue("disassembledItems", disassembledItems)

      output:setInstanceValue("description", string.format("Left-click to reobtain the gun and mods.\n^#96cbe7;Contains %d distinct items.^reset;", 1 + #disassembledItems))

      gun.config.tooltipFields = sb.jsonMerge(gun.config.tooltipFields, gun.parameters.tooltipFields or {})
      gun.config.tooltipFields.subtitle = "^#d93a3a;Disassembled Gun^reset;"
      gun.config.tooltipFields.objectImage = gun.directory .. gun.config.inventoryIcon
      output:setInstanceValue("tooltipFields", gun.config.tooltipFields)

      return output
      
    end
  end
end