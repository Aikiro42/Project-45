require "/scripts/augments/item.lua"
require "/scripts/util.lua"

-- @param input: ItemDescriptor
function disassemble(input, transformItemId)

  if input.parameters or transformItemId then

    input.parameters = input.parameters or {}

    local savedGunSeed = input.parameters.seed or 0
    local wasBought = input.parameters.bought
    local savedUpgradeParameters = input.parameters.upgradeParameters
    local weaponUpgradeStatus = input.parameters.weaponUpgradeStatus or 0

    if weaponUpgradeStatus >= 2 then
      savedUpgradeParameters = nil
    end

    if input.parameters.project45GunModInfo and (input.parameters.isModded or transformItemId) then

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
      local gun
      if transformItemId then
        gun = root.itemConfig({name = transformItemId})
      else
        gun = root.itemConfig(input)
      end
      local gunConfig = gun.config

      output:setInstanceValue("gunItem", {name = transformItemId or input.name, parameters = {
        upgradeParameters = savedUpgradeParameters,
        seed = savedGunSeed,
        bought = wasBought,
        weaponUpgradeStatus = weaponUpgradeStatus >= 2 and 3 or 0  -- see project45-essentialgunoil.augment
      }})
      output:setInstanceValue("shortdescription", gunConfig.shortdescription)
      output:setInstanceValue("rarity", gunConfig.rarity)
      sb.logInfo(sb.printJson(disassembledItems, 1))
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