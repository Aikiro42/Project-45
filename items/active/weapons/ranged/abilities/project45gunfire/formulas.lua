---@diagnostic disable-next-line: lowercase-global
formulas = {}

function formulas.stockAmmoDamageMult(stockAmmo, maxAmmo)
  return 1 + (stockAmmo * 0.1 / maxAmmo * 3)
end

function formulas.critDamage(critChance, baseCritDamageMult, isCrit, critTier)
  critTier = critTier or math.floor(critChance)
  if critTier == 0 then -- base
    return isCrit and baseCritDamageMult or 1
  end
  -- crit tier = floor(crit chance)
  -- crit damage = base crit damage + crit tier
  -- crit damage + 1 if super crit; crit damage + 0 otherwise
  return math.max(1, baseCritDamageMult + critTier + (isCrit and 1 or 0))
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

  if type(damageModifiers) == "table" then
    -- sb.logInfo("-------------------------------------------------")
    for k, v in pairs(damageModifiers) do
      -- sb.logInfo(string.format("%s %s to damage", v.type or "???", k))
      if v.type == "mult" then
        mults = mults * (v.value or 1)
      elseif v.type == "add" then
        adds = adds + (v.value or 0)
      end
    end
  end
  
  return baseDamage * mults + adds

end
