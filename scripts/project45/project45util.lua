project45util = {}

function project45util.clamp(x, min, max)
    if x < min then
      return min
    elseif x > max then
      return max
    else
      return x
    end
end

function project45util.diceroll(chance)
  return math.random() <= chance
end