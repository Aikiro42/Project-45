project45util = {}

function project45util.split(str, sep)  
  sep = sep or "%s"
  local t = {}
  for str in string.gmatch(str, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

-- @return 2 if major version different
-- @return 1 if minor version different
-- @return 0 otherwise
function project45util.compareVersions(old, new)
  local oldV = project45util.split(old, '.')
  local newV = project45util.split(new, '.')
  
  -- major
  if oldV[1] ~= newV[1] then return false end
  
  -- minor
  if oldV[2] ~= newV[2] then return false end
end

function project45util.truncatei(n, places)
  local ten = 10 ^ places
  return math.floor(n / ten) * ten
end

function project45util.truncatef(n, places)
  local ten = 10 ^ places
  return math.floor(n * ten) / ten
end

-- draws a quadratic bezier curve from spoint to epoint
function project45util.drawBezierCurve(nsegments, spoint, epoint, cpoint, tCondFunc, tCondFuncLastPoint)
  
  tCondFunc = tCondFunc or function(a, b) return false end
  
  local curve = {}
  -- for each segment
  local prev = spoint
  for i = 1, nsegments do
    local t = i/nsegments

    local next = vec2.add(
      vec2.mul(vec2.add(vec2.mul(spoint, 1 - t), vec2.mul(cpoint, t)), 1 - t),
      vec2.mul(vec2.add(vec2.mul(cpoint, 1 - t), vec2.mul(epoint, t)), t)
    )

    local tCondFunc = tCondFunc(prev, next)
    if tCondFunc then
      if type(tCondFunc) == "table" then
        next = tCondFunc
        table.insert(curve, {
          prev, next
        })    
      end
      break
    end

    table.insert(curve, {
      prev, next
    })

    prev = next
  end

  return curve
  
end

function project45util.colorText(color, text)
  if not color then return text end
  if type(color) == "table" then
    color = "#" .. rgbToHex(color)
  end
  return "^" .. color .. ";" .. text .. "^reset;"
end

function project45util.rgbToHex(rgbArray)
  local hexString = string.format("%02X%02X%02X", rgbArray[1], rgbArray[2], rgbArray[3])
  return hexString
end

function project45util.capitalize(str)
  if str then
    return (str:gsub("^%l", string.upper))
  end
  return nil
end

function project45util.diceroll(chance)
  return math.random() <= chance
end

function project45util.circle(radius, segments)
  segments = segments or 15
  local arc = 2 * math.pi / segments
  local vecs = {}
  for i=1, segments do
    table.insert(vecs, vec2.rotate({radius, 0}, arc * i))
  end
  return vecs
end

function project45util.boolXor(a, b)
  -- turn bools into integers
  local alpha = a and 1 or 0
  local beta = b and 1 or 0
  -- use bitwise operator to return output
  return alpha ~ beta > 0
end

function project45util.Set(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function project45util.isItemInList(list, item)
  for i, _ in ipairs(list) do
    if item == list[i] then return true end
  end
  return false
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

function project45util.__vividness(color)
  -- vividness is distance from "gray diagonal"
  --[[
      Chen, T. (January 2022)
      A measurement of the overall vividness of a color image based on RGB color model.
      Electronic Imaging.
      Society for Imaging Science and Technology.
      DOI: https://doi.org/10.2352/EI.2022.34.15.COLOR-245
  --]]
  return (math.sqrt(6)/3) * math.sqrt(
      color[1]^2
      + color[2]^2
      + color[3]^2
      - (color[1] * color[2])
      - (color[1] * color[3])
      - (color[2] * color[3])
  )
end

function project45util.moreVividColor(color1, color2)
  local alpha = 255

  -- compare color transparency; choose less transparent color
  if #color1 > 3 and #color2 > 3 then
      alpha = math.max(color1[4], color2[4])
  end
  
  -- choose more vivid color
  local chosen = project45util.__vividness(color1) > project45util.__vividness(color2) and color1 or color2
  table.insert(chosen, alpha)
  return chosen
end

function project45util.charat(s, i)
  return string.sub(s, i, i)
end