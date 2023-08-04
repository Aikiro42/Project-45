project45util = {}

function project45util.diceroll(chance)
  return math.random() <= chance
end

function project45util.Set(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function project45util.List(set)
  local list = {}
  for i, _ in pairs(set) do table.insert(list, i) end
  return list
end

function project45util.mergeLists(lista, listb)
  local listc = {}
  while #lista > 0 and #listb > 0 do
    if lista[1] <= listb[1] then
      table.insert(listc, lista[1])
      table.remove(lista, 1)
    else
      table.insert(listc, listb[1])
      table.remove(listb, 1)
    end
  end

  while #lista > 0 do
    table.insert(listc, lista[1])
    table.remove(lista, 1)
  end


end