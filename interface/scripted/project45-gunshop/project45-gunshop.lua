require "/scripts/util.lua"
require "/scripts/set.lua"

local radioButtonIDs = {
  "guns",
  "mods",
  "stat",
  "ammo",
  "util",
}

function configParameter(item, keyName, defaultValue)
  if item.parameters[keyName] ~= nil then
    return item.parameters[keyName]
  elseif item.config[keyName] ~= nil then
    return item.config[keyName]
  else
    return defaultValue
  end
end

function init()
  self.itemList = "itemScrollArea.itemList"
  self.totalCost = "lblCostTotal"
  self.listItems = {}

  self.goods = config.getParameter("goods", {
    guns = {},
    mods = {},
    stat = {},
    ammo = {},
    util = {}
  })

  self.seededItems = set.new(
    config.getParameter("seededItems", {})
  )
  self.seededItems = set.union(self.seededItems, set.new(self.goods.guns))
  self.noInflation = set.new(
    config.getParameter("noInflation", {})
  )
  
  self.mode = "guns"
  widget.setSelectedOption("shopTabs", 1)

  self.selectedItem = nil
  self.prevSelectedItem = nil
  populateItemList(true, self.mode)
end

function update(dt)
  populateItemList(nil, nil, true)
end

function radioButton(radioButtonId)
  return radioButtonIDs[tonumber(radioButtonId)]
end

function switchMode(mode)
  populateItemList(true, radioButton(mode))
end

function incrementQuantity()
  updateQuantity(self.selectedItem or self.prevSelectedItem, 1)
end

function decrementQuantity()
  updateQuantity(self.selectedItem or self.prevSelectedItem, -1)
end

function updateQuantity(item, delta)
  if not item then return end
  local listItem = string.format("%s.%s", self.itemList, item)
  local itemData = widget.getData(listItem)
  itemData.item.count = math.max(1, itemData.item.count + delta)
  updateListItemText(listItem, itemData, item == self.selectedItem)
  showWeapon(itemData.item)
end

function updateListItemText(listItem, newListItemData, isSelected)
  local item = newListItemData.item
  local name = configParameter(item, "shortdescription", "Failed to reach item name")
  local cost = configParameter(item, "price", 1) * (configParameter(item, "noInflation", false) and 1 or 10)

  -- widget.setItemSlotItem(string.format("%s.itemIcon", listItem), generatedItem)
  widget.setText(string.format("%s.itemName", listItem), "^#FF9000;" .. name .. (item.count > 1 and (" (" .. item.count .. ")") or ""))
  widget.setText(string.format("%s.priceLabel", listItem), (isSelected and "^#190700;" or "^#FF9000;") .. math.ceil(cost * item.count))
  widget.setData(listItem, newListItemData)
  local unavailable = cost * item.count > player.currency("money")
  widget.setVisible(string.format("%s.unavailableoverlay", listItem), unavailable)
  widget.setVisible(string.format("%s.unavailableunderlay", listItem), unavailable)

end

function populateItemList(forceRepop, mode, idle)
  local playerMoney = player.currency("money")
  self.mode = mode or self.mode
  if idle then return end
  if forceRepop then
    widget.clearListItems(self.itemList)
    self.listItems = {}
    local showEmptyLabel = true
    local goods = self.goods[mode]

    for _, item in ipairs(goods) do
      -- local generatedItem = root.createItem(item, world.threatLevel())
      if type(item) == "string" then
        item = {
          name = item,
          count = 1,
          parameters= {
            noSeed = true,
            noInflation = self.noInflation[item]
          }
        }
      else
        item.parameters = item.parameters or {}
        item.parameters.noInflation = self.noInflation[item]
        item.count = item.count or 1
      end

      local generatedItem = root.itemConfig(item)
      generatedItem.name = item.name
      generatedItem.count = item.count
      --local randomWeapon = self.weaponTypes[(math.random(1, 4294967295) % #self.weaponTypes) + 1]
      --root.itemConfig(randomWeapon)

      -- local config = root.itemConfig(item).config
      showEmptyLabel = false

      local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
      table.insert(self.listItems, listItem)
      local name = configParameter(generatedItem, "shortdescription", "Failed to reach item name")
      local cost = configParameter(generatedItem, "price", 1) * (configParameter(generatedItem, "noInflation", false) and 1 or 10)
      local icon
      if not pcall(function()
        icon = util.absolutePath(generatedItem.directory, generatedItem.config.inventoryIcon)
      end) then
        icon = ""
      end
      
      -- widget.setItemSlotItem(string.format("%s.itemIcon", listItem), generatedItem)
      widget.setText(string.format("%s.itemName", listItem), "^#FF9000;" .. name .. (item.count > 1 and (" (" .. item.count .. ")") or ""))
      widget.setImage(string.format("%s.itemImage", listItem), icon)
      widget.setText(string.format("%s.priceLabel", listItem), "^#FF9000;" .. math.ceil(cost * item.count))
      widget.setData(listItem,
      {
        item = generatedItem,
        icon = icon,
        price = math.ceil(cost)
      }
      )
      
      local unavailable = cost * item.count > playerMoney
      widget.setVisible(string.format("%s.unavailableoverlay", listItem), unavailable)
      widget.setVisible(string.format("%s.unavailableunderlay", listItem), unavailable)
    
    end

    self.selectedItem = nil
    showWeapon(nil)

    widget.setVisible("emptyLabel", showEmptyLabel)
  else
    for _, listItem in ipairs(self.listItems) do
      updateListItemText(listItem, widget.getData(listItem))
    end
    local selectedItem = widget.getListSelected(self.itemList)
    if selectedItem then
      selectedItem = string.format("%s.%s", self.itemList, selectedItem)
      updateListItemText(selectedItem, widget.getData(selectedItem), true)
    end
  end
end

function showWeapon(item)
  local playerMoney = player.currency("money")
  local enableButton = false

  if item then
    local cost = configParameter(item, "price")
    enableButton = playerMoney >= cost
    widget.setText(self.totalCost, string.format("%s", "^#190700;" .. math.ceil(cost * (item.count or 1))))
  else
    widget.setText(self.totalCost, string.format("^#190700;--"))
  end

  widget.setButtonEnabled("btnBuy", enableButton)
  widget.setText("btnBuy", enableButton and "^#FF9000;Buy" or "^#6e2900;Buy")
end

function itemSelected()
  local listItem = widget.getListSelected(self.itemList)
  
  -- deselect
  if self.prevSelectedItem then
    local listItem = string.format("%s.%s", self.itemList, self.prevSelectedItem)
    local itemData = widget.getData(listItem)
    widget.setItemSlotItem(string.format("%s.itemIcon", listItem), nil)  
    widget.setImage(string.format("%s.itemImage", listItem), itemData.icon)  
    widget.setText(string.format("%s.priceLabel", listItem), "^#FF9000;" .. itemData.price * (itemData.item.count or 1))
  end
  
  self.prevSelectedItem = listItem
  self.selectedItem = listItem

  -- select
  if listItem then
    local listItem = string.format("%s.%s", self.itemList, self.selectedItem)
    local itemData = widget.getData(listItem)
    if not itemData.itemGen then
      itemData.itemGen = root.createItem({name=itemData.item.name, count=1, parameters=itemData.item.parameters})
      widget.setData(listItem, itemData)
    end
    widget.setImage(string.format("%s.itemImage", listItem), "")
    widget.setItemSlotItem(string.format("%s.itemIcon", listItem), itemData.itemGen)    
    widget.setText(string.format("%s.priceLabel", listItem), "^#190700;" .. itemData.price * (itemData.item.count or 1))
    showWeapon(itemData.item)
  end
end

function purchase()
  if self.selectedItem then
    local listItem = string.format("%s.%s", self.itemList, self.selectedItem)
    local selectedData = widget.getData(listItem)
    local selectedItem = selectedData.item
    selectedItem.parameters.noSeed = nil

    if selectedItem then
      --If we successfully consumed enough currency, give the new item to the player
      local consumedCurrency = player.consumeCurrency("money", configParameter(selectedItem, "price") * selectedItem.count)

      if consumedCurrency then
        local purchased
        local count = selectedItem.count or 1
        selectedItem.count = 1

        if self.seededItems[selectedItem.name] then
          for i=1, count do
            local seed = math.floor(math.random() * 2147483647)
            selectedItem.parameters.bought = true
            purchased = root.createItem(selectedItem, math.floor(math.random() * 10), seed)
            player.giveItem(purchased)
          end
        else
          purchased = root.createItem(selectedItem)
          for i=1, count do
            player.giveItem(purchased)
          end
        end
      end

    end
    populateItemList(false, self.mode)
  end
end
