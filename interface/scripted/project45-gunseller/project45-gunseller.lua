function init()
  local sellFactor = config.getParameter("sellFactor")
  self.cachedItems = {}
  --[[
  local acceptItems = config.getParameter("acceptItems")
  self.itemValues = {}
  for _, itemName in pairs(acceptItems) do
    local itemConfig = root.itemConfig(itemName)
    if itemConfig.config.price and itemConfig.config.price > 0 then
      self.itemValues[itemName] = math.ceil(itemConfig.config.price * sellFactor)
    end
  end
  --]]
end

function update(dt)
  widget.setText("lblMoney", shorthand(valueOfContents()))
end

function triggerShipment(widgetName, widgetData)
  world.sendEntityMessage(pane.containerEntityId(), "triggerShipment")
  local total = valueOfContents()
  if total > 0 then
    player.giveItem({name = "money", count = total})
  end
  pane.dismiss()
end

function valueOfContents()
  local value = 0
  local allItems = widget.itemGridItems("itemGrid")
  for _, item in pairs(allItems) do
    if not self.cachedItems[item.name] then
      self.cachedItems[item.name] = root.itemConfig(item.name)
    end
    local itemCost = item.parameters.price or self.cachedItems[item.name].config.price or 0
    value = value + itemCost * item.count
  end
  return value
end

function shorthand(num)

  if num < 10000 then
    return num
  elseif num < 1e6 then
    return string.format("%.1fK", num / 1000)
  elseif num < 1e9 then
    return string.format("%.1fM", num / 1e6)
  elseif num < 1e12 then
    return string.format("%.1fB", num / 1e9)
  else
    return "A LOT"
  end

end
