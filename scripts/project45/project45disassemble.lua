require "/scripts/augments/item.lua"
require "/scripts/util.lua"

-- @param input: ItemDescriptor
-- @param transformerId: string
-- ID of the transformer mod applied to the weapon that caused it to be disassembled
-- Can be `nil`. If it is, then the item is transformed into the previous item ID stored in the stack.
-- @param transformerItemId: string
-- ID of the item into which the disassembled will turn into
-- Can be `nil`, Irrelevant if `transformerId` is nil
function disassemble(input, transformerId, transformItemId)

  if input.parameters or transformerId then

    input.parameters = input.parameters or {}
    
    -- [(firstPrevTransformItemId, firstTransformerId), ..., (lastPrevTransformItemId, lastTransformerId)]
    local transformerStack = input.parameters.transformerStack or {}
    
    local savedGunSeed = input.parameters.seed or 0
    local wasBought = input.parameters.bought
    local savedUpgradeParameters = input.parameters.upgradeParameters
    local weaponUpgradeStatus = input.parameters.weaponUpgradeStatus or 0

    if weaponUpgradeStatus >= 2 then
      savedUpgradeParameters = nil
    end

    if input.parameters.project45GunModInfo and (input.parameters.isModded or transformerId or #transformerStack > 0) then
      -- modded or transformed; do transformation process
      
      local disassembledItems = {}

      -- add mods to disassembledItems
      if input.parameters.modSlots then
        for k, v in pairs(input.parameters.modSlots) do
          local isAbility = {ability=true, shiftAbility=true}
          if not isAbility[k] then
            table.insert(disassembledItems, v[2])
          end
        end
      end
      
      -- add installed stats to disassembledItems
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

      -- add stockAmmo to disassembledItems
      local stockAmmo = (input.parameters.savedGunState or {stockAmmo = 0}).stockAmmo or 0
      if stockAmmo > 0 then
        table.insert(disassembledItems, {
          name = "project45-ammostock",
          parameters = {
            ammo = stockAmmo
          }})
      end

      local output = Item.new({name="project45-disassembledguncase", count=1, parameters={}})
      local gun, prevTransformItemId, prevTransformer, nextForm
      if transformerId then -- transformation
        prevTransformItemId = input.name
        prevTransformer = transformerId
        table.insert(transformerStack, {prevTransformItemId, prevTransformer})
        gun = root.itemConfig({name = transformItemId})
        nextForm = transformItemId
      else  -- disassembly
        if #transformerStack > 0 then -- transformation stack has elements, pop and revert to previous transformation
          local prevTransform = table.remove(transformerStack, #transformerStack)
          prevTransformItemId = prevTransform[1]
          prevTransformer = prevTransform[2]
          table.insert(disassembledItems, prevTransformer)  -- add previous transformer to disassembled items
          gun = root.itemConfig({name = prevTransformItemId})
          nextForm = prevTransformItemId
        else  -- transformation stack empty; item is in original form, so just disassemble item
          gun = root.itemConfig(input)
          nextForm = input.name
        end
      end
      local gunConfig = gun.config

      output:setInstanceValue("gunItem", {name = nextForm, parameters = {
        upgradeParameters = savedUpgradeParameters,
        seed = savedGunSeed,
        bought = wasBought,
        weaponUpgradeStatus = weaponUpgradeStatus >= 2 and 3 or 0,  -- see project45-essentialgunoil.augment
        transformerStack = transformerStack  -- update transformerStack
      }})
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