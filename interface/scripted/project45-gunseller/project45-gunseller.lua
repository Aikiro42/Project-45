function init()
  require "/scripts/set.lua"
  
  self.sellFactor = config.getParameter("sellFactor", 1)
  self.cachedItems = {}
  self.appreciateItems = {}
  self.appreciateTags = {}
  self.appreciateCategories = {}
  local appreciates = config.getParameter("appreciate", {nil})
  for _, appreciate in ipairs(appreciates) do
    if appreciate.item then
      self.appreciateItems[appreciate.item] = appreciate.factor
    end
    if appreciate.tag then
      self.appreciateTags[appreciate.tag] = appreciate.factor
    end
    if appreciate.category then
      self.appreciateCategories[appreciate.category] = appreciate.factor
    end
  end
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

    -- obtain item config
    if not self.cachedItems[item.name] then
      self.cachedItems[item.name] = root.itemConfig(item.name)
    end
    local itemConfig = self.cachedItems[item.name].config
    local itemCategory = item.parameters.category or itemConfig.category or "unknown"

    -- get item cost
    local itemCost = item.parameters.price or itemConfig.price or 0
    
    -- calculate item, category and tag factor
    local itemFactor = self.appreciateItems[item.name] or 1
    itemFactor = itemFactor * (self.appreciateCategories[itemCategory] or 1)
    local itemTags = item.parameters.itemTags or itemConfig.itemTags or {nil}
    for _, tag in ipairs(itemTags) do
      itemFactor = itemFactor * (self.appreciateTags[tag] or 1)
    end

    -- add calculated itemvalue to item cost
    value = value + itemCost * item.count * self.sellFactor * itemFactor
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
