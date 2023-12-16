require "/scripts/util.lua"

local radioButtonIDs = {
  "guns",
  "mods",
  "stat",
  "ammo",
  "util",
}

function init()
  self.itemList = "itemScrollArea.itemList"
  self.totalCost = "lblCostTotal"

  self.goods = config.getParameter("goods", {
    guns = {},
    mods = {},
    stat = {},
    ammo = {},
    util = {}
  })
  
  self.mode = "guns"
  widget.setSelectedOption("shopTabs", 1)

  self.selectedItem = nil
  self.prevSelectedItem = nil
  
  populateItemList(true, self.mode)
end

function update(dt)
  populateItemList()
end

function radioButton(radioButtonId)
  return radioButtonIDs[tonumber(radioButtonId)]
end

function switchMode(mode)
  populateItemList(true, radioButton(mode))
end

function populateItemList(forceRepop, mode)
  local playerMoney = player.currency("money")
  self.mode = mode or self.mode
  if forceRepop then
    widget.clearListItems(self.itemList)

    local showEmptyLabel = true
    local goods = self.goods[mode]

    for _, item in ipairs(goods) do
      local generatedItem = root.createItem(item, world.threatLevel())
      --local randomWeapon = self.weaponTypes[(math.random(1, 4294967295) % #self.weaponTypes) + 1]
      --root.itemConfig(randomWeapon)

      local config = root.itemConfig(item).config
      
      showEmptyLabel = false

      local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
      local name = config.shortdescription or "Failed to reach item name"
      local cost = config.price or 1
      generatedItem.parameters.price = cost

      widget.setItemSlotItem(string.format("%s.itemIcon", listItem), generatedItem)
      widget.setText(string.format("%s.itemName", listItem), "^#FF9000;" .. name .. (generatedItem.count > 1 and (" (" .. generatedItem.count .. ")") or ""))
      
      widget.setText(string.format("%s.priceLabel", listItem), "^#FF9000;" .. math.ceil(cost * generatedItem.count))

      widget.setData(listItem,
      {
        item = generatedItem,
        price = math.ceil(cost)
      }
      )
      
      widget.setVisible(string.format("%s.unavailableoverlay", listItem), cost * generatedItem.count > playerMoney)
    end

    self.selectedItem = nil
    showWeapon(nil)

    widget.setVisible("emptyLabel", showEmptyLabel)
  end
end

function showWeapon(item)
  local playerMoney = player.currency("money")
  local enableButton = false

  if item then
    local cost = item.parameters.price
    enableButton = playerMoney >= cost
    widget.setText(self.totalCost, string.format("%s", "^#190700;" .. math.ceil(cost * (item.count or 1))))
  else
    widget.setText(self.totalCost, string.format("^#190700;--"))
  end

  widget.setButtonEnabled("btnBuy", enableButton)
end

function itemSelected()
  local listItem = widget.getListSelected(self.itemList)
  
  if self.prevSelectedItem then
    local listItem = string.format("%s.%s", self.itemList, self.prevSelectedItem)
    local itemData = widget.getData(listItem)
    widget.setText(string.format("%s.priceLabel", listItem), "^#FF9000;" .. itemData.price * (itemData.item.count or 1))
  end
  
  self.prevSelectedItem = listItem
  self.selectedItem = listItem

  if listItem then
    local listItem = string.format("%s.%s", self.itemList, self.selectedItem)
    local itemData = widget.getData(listItem)
    widget.setText(string.format("%s.priceLabel", listItem), "^#190700;" .. itemData.price * (itemData.item.count or 1))
    showWeapon(itemData.item)
  end
end

function purchase()
  if self.selectedItem then
    local listItem = string.format("%s.%s", self.itemList, self.selectedItem)
    local selectedData = widget.getData(listItem)
    local selectedItem = selectedData.item

    if selectedItem then
      --If we successfully consumed enough currency, give the new item to the player
      local consumedCurrency = player.consumeCurrency("money", selectedItem.parameters.price * selectedItem.count)

      if consumedCurrency then
        player.giveItem(selectedItem)
        --[[
        widget.setData(listItem,
        {
          price = "Sold!"
        }
        )
        widget.setVisible(string.format("%s.unavailableoverlay", listItem), true)
        widget.setText(string.format("%s.priceLabel", listItem), "^#190700;Sold!")
        widget.setText(self.totalCost, string.format("^#190700;--"))
        widget.setButtonEnabled("btnBuy", false)
        --]]
      end

    end
    populateItemList(true, self.mode)
  end
end
