require "/scripts/augments/item.lua"

function apply(input)
  local output = Item.new(input)
  output.config.tooltipFields = nil
  sb.logInfo(sb.printJson(output.config, 1))
  sb.logInfo(sb.printJson(input.parameters, 1))
  -- recursivePrint(output.config)
  -- recursivePrint(input.parameters)
end

function recursivePrint(t, tabs)
  tabs = tabs or 0
  if type(t) == "table" then
    for k, v in pairs(t) do
      sb.logInfo(k .. ":")
      recursivePrint(t[k], tabs + 1)
    end
  else
    local tabString = ""
    for n=1, tabs do
      tabString = tabString .. "  "
    end
    sb.logInfo(tabString .. sb.print(t))
  end
end
