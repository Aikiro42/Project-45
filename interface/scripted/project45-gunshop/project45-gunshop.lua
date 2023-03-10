require "/scripts/util.lua"

function init()
  self.itemList = "itemScrollArea.itemList"
  self.totalCost = "lblCostTotal"

  self.weapons = config.getParameter("weapons", {"project45-pistol"})
  
  self.selectedItem = nil
  self.prevSelectedItem = nil
	
  populateItemList(true)
end

function update(dt)
  populateItemList()
end

function populateItemList(forceRepop)
  local playerMoney = player.currency("money")

  if forceRepop then
    widget.clearListItems(self.itemList)

    local showEmptyLabel = true

    for i = 1, #self.weapons do
      local generatedWeapon = root.createItem(self.weapons[i], world.threatLevel())
      --local randomWeapon = self.weaponTypes[(math.random(1, 4294967295) % #self.weaponTypes) + 1]
      --root.itemConfig(randomWeapon)

      local config = generatedWeapon.parameters

      showEmptyLabel = false

      local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
      local name = config.shortdescription or config.shortdescription or "Failed to reach item name"
      local cost = config.price or 1

      widget.setItemSlotItem(string.format("%s.itemIcon", listItem), generatedWeapon)
      widget.setText(string.format("%s.itemName", listItem), "^#FF9000;" .. name)
      
      widget.setText(string.format("%s.priceLabel", listItem), "^#FF9000;" .. math.ceil(cost))

      widget.setData(listItem,
      {
        item = generatedWeapon,
        price = math.ceil(cost)
      }
      )
      
      widget.setVisible(string.format("%s.unavailableoverlay", listItem), cost > playerMoney)
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
    widget.setText(self.totalCost, string.format("%s", "^#190700;" .. math.ceil(cost)))
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
    sb.logInfo(sb.printJson(itemData))
    widget.setText(string.format("%s.priceLabel", listItem), "^#FF9000;" .. itemData.price)
  end
  
  self.prevSelectedItem = listItem
  self.selectedItem = listItem

  if listItem then
    local listItem = string.format("%s.%s", self.itemList, self.selectedItem)
    local itemData = widget.getData(listItem)
    sb.logInfo(sb.printJson(itemData))
    widget.setText(string.format("%s.priceLabel", listItem), "^#190700;" .. itemData.price)
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
	  local consumedCurrency = player.consumeCurrency("money", selectedItem.parameters.price)
	  if consumedCurrency then
		player.giveItem(selectedItem)
	    widget.setData(listItem,
		  {
		    price = "Sold!"
		  }
	    )
	    widget.setVisible(string.format("%s.unavailableoverlay", listItem), true)
	    widget.setText(string.format("%s.priceLabel", listItem), "^#190700;Sold!")
		widget.setText(self.totalCost, string.format("^#190700;--"))
		widget.setButtonEnabled("btnBuy", false)
	  end
    end
    populateItemList()
  end
end
