---@diagnostic disable-next-line: lowercase-global
formulas = {}

function formulas.stockAmmoDamageMult(stockAmmo, maxAmmo)
  -- sb.logInfo(string.format("stockAmmo=%d maxAmmo=%d dmgMult=%.2f", stockAmmo, maxAmmo, dmgMult))
  return 1 + ((stockAmmo * 0.1) / (maxAmmo * 6))
end

function formulas.critScaling(baseCritDamageMult, alpha)
  local alpha = alpha or 0.5 -- anti-scaling factor
  return (baseCritDamageMult / (1 + alpha * (baseCritDamageMult - 1)))
end

function formulas.critDamage(critChance, baseCritDamageMult, isCrit, critTier, scaling, alpha)
  
  critTier = critTier or math.floor(math.max(0, critChance))
  local scaling = scaling or formulas.critScaling(baseCritDamageMult, alpha)
  --[[
  
  When critting below or at 100% crit (i.e. max crit tier is 1),
  finalCritDamage is consistent with baseCritDamageMult.
  Beyond critTier1, finalCritDamage scales logarithmically.
  The higher baseCritDamageMult is, the lower the benefits of each tier.

  --]]

  -- finalCritDamage is undefined if critTier == 0
  if critTier == 0 then -- base
    return isCrit and baseCritDamageMult or 1
  end
  
  local finalCritTier = critTier + (isCrit and 1 or 0)
  return baseCritDamageMult + baseCritDamageMult * math.log(finalCritTier) * scaling
end

-- Calculates the damage per shot of the weapon.
function formulas.damagePerShot(
  baseDamage,
  damageModifiers
  )

  --[[

  local critDmg = self:crit()

  local finalDmg = self.baseDamage
  * (noDLM and 1 or config.getParameter("damageLevelMultiplier", 1))
  * self.currentChargeDamage -- up to 2x at full overcharge
  * self.reloadRatingDamage -- as low as 0.8 (bad), as high as 1.5 (perfect)
  * critDmg -- this way, rounds deal crit damage individually
  * (self.passiveDamageMult or 1) -- provides a way for passives to modify damage
  * self.weapon.stockAmmoDamageMult
  / self.projectileCount
  
  return finalDamage * self.powerMultiplier
  --]]

  local adds = 0
  local mults = 1

  -- local multsText = ""
  -- local addsText = ""

  if type(damageModifiers) == "table" then
    -- sb.logInfo("-------------------------------------------------")
    for k, v in pairs(damageModifiers) do
      -- sb.logInfo(string.format("%s %s to damage", v.type or "???", k))
      if v.type == "mult" then
        --[[
        if v.value ~= 1 then
          multsText = multsText .. (multsText == "" and "" or " * ") .. string.format("%.2f (%s)", v.value or 1, k)
        end
        --]]
        mults = mults * (v.value or 1)
      elseif v.type == "add" then
        --[[
        if v.value ~= 0 then
          addsText = addsText .. (addsText == "" and "" or " + ") .. string.format("%.2f (%s)", v.value or 0, k)
        end
        --]]
        adds = adds + (v.value or 0)
      end
    end
  end

  -- local finalDamage = baseDamage * mults + adds
  -- sb.logInfo("" ..finalDamage.. " = " ..baseDamage.. " * [ " ..multsText.." ] + [ " ..addsText.. " ]")
  
  return baseDamage * mults + adds

end

-- @param reloadTime: float (seconds) - duration of reload
-- @param goodTime: float (seconds) - duration of good reload timeframe
-- @param perfectTime: float (seconds) - duration of perfect reload timeframe
-- @param reloadOffsetRatio: float (%) - where along reload time center of timeframe is; 0.5 (center) by default
-- @param perfectReloadRatio: float (%) - where along reload time center of perfect timeframe is; 0.5 (center by default)
function formulas.quickReloadTimeframe(reloadTime, goodTime, perfectTime, reloadOffsetRatio,  perfectOffsetRatio)
  
  goodTime = math.min(reloadTime, goodTime)
  perfectTime = math.min(goodTime, perfectTime)
  reloadOffsetRatio = util.clamp(reloadOffsetRatio or 0.5, 0, 1)

  -- [     |++++++|!!!|++++++|   ]
  --       a      b   c      d
  local a, b, c, d

  local goodTimeRatio = goodTime / reloadTime
  a = util.clamp(reloadOffsetRatio - (goodTimeRatio / 2), 0, 1)
  d = util.clamp(reloadOffsetRatio + (goodTimeRatio / 2), 0, 1)
  if d - a < goodTimeRatio then
    if a == 0 then
      d = goodTimeRatio
    elseif d == 1 then
      a = 1 - goodTimeRatio
    end
  end

  perfectOffsetRatio = util.clamp(perfectOffsetRatio or reloadOffsetRatio, a, d)
  local perfectTimeRatio = perfectTime / reloadTime
  b = util.clamp(perfectOffsetRatio - (perfectTimeRatio / 2), a, d)
  c = util.clamp(perfectOffsetRatio + (perfectTimeRatio / 2), a, d)
  if c - b < perfectTimeRatio then
    if b == a then
      c = util.clamp(a + perfectTimeRatio, a, d)
    elseif d == c then
      b = util.clamp(d - perfectTimeRatio, a, d)
    end
  end

  return {a, b, c, d}

end

-- Inverse of formulas.quickReloadTimeframe().
-- @return {reloadTime:float, goodTime:float, perfectTime:float, reloadOffsetRatio:float, perfectOffsetRatio:float}
function formulas.quickReloadParameters(reloadTime, quickReloadTimeframe)

  local goodReloadRatio = quickReloadTimeframe[4] - quickReloadTimeframe[1]
  local perfectReloadRatio = quickReloadTimeframe[3] - quickReloadTimeframe[2]

  local reloadOffsetRatio = util.clamp( quickReloadTimeframe[1] + goodReloadRatio / 2, 0, 1)
  local perfectOffsetRatio = util.clamp( quickReloadTimeframe[2] + perfectReloadRatio / 2, 0, 1)
  local goodTime = reloadTime * goodReloadRatio
  local perfectTime = reloadTime * perfectReloadRatio

  return {
    reloadTime = reloadTime,
    goodTime = goodTime,
    perfectTime = perfectTime,
    reloadOffsetRatio = reloadOffsetRatio,
    perfectOffsetRatio = perfectOffsetRatio
  }

end