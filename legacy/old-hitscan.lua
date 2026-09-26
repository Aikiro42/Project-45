function SynthetikMechanics:fireHitscan(projectileType)

    -- scan hit down range
    -- hitreg[2] is where the bullet trail terminates,
    -- hitreg[3] is the array of hit entityIds
    local hitReg = self:hitscan()
    local crit = self:crit()
    local statusDamage = "project45damage"
    storage.critStats.shots = storage.critStats.shots + 1
    if crit > 1 then
      storage.critStats.crits = storage.critStats.crits + 1
      statusDamage = "project45critdamage"
    end
    -- if damageable entity has been detected (hitreg[3] is not nil), damage it

    if #hitReg[3] > 0 then
      for _, hitId in ipairs(hitReg[3]) do
        if world.entityExists(hitId) then
          
          world.sendEntityMessage(hitId, "applyStatusEffect", self.projectileParameters.hitscanDamageKind or statusDamage, self:damagePerShot() * crit / (self.usedByNPC and 2 or 1), entity.id())

          -- if self.projectileParameters.hitregPower == 0 then
            for i, stateffect in ipairs(self.projectileParameters.statusEffects) do
              world.sendEntityMessage(hitId, "applyStatusEffect", stateffect)
            end
          -- end
        end
      end
    end

    -- bullet trail info inserted to projectile stack that's being passed to the animation script
    -- each bullet trail in the stack is rendered, and the lifetime is updated in this very script too
    local life = self.projectileParameters.fadeTime or 0.5
    table.insert(self.projectileStack, {
      width = self.projectileParameters.hitscanWidth,
      origin = hitReg[1],
      destination = hitReg[2],
      lifetime = life,
      maxLifetime = life,
      color = self.projectileParameters.hitscanColor
    })

    -- hitscan explosion
    --[[
    {
      action="loop",
      count=6,
      body={
        {
          action="particle",
          specification={
            type="ember"
            size=1,
            color={255, 255, 200, 255},
            light={65, 65, 51},
            fullbright=true,
            destructionTime=0.2,
            destructionAction="shrink",
            fade=0.9,
            initialVelocity={0, 5},
            finalVelocity={0, -50},
            approach={0, 30},
            timeToLive=0,
            layer="middle",
            variance={
              position={0.25, 0.25},
              size=0.5,
              initialVelocity={10, 10},
              timeToLive=0.2
            }
          }
        }
      }
    }  

    local hitscanActionsOnReap = {
      {
        action = "config",
        file = "/projectiles/explosions/project45_hitexplosion/project45_hitscanexplosion.config"
      }
    }
    --]]
    local hitscanActionsOnReap = {
      {
        action="loop",
        count=6,
        body={
          {
            action="particle",
            specification={
              type="ember",
              size=1,
              color=self.projectileParameters.hitscanColor or {255, 255, 200, 255},
              light={65, 65, 51},
              fullbright=true,
              destructionTime=0.2,
              destructionAction="shrink",
              fade=0.9,
              initialVelocity={0, 5},
              finalVelocity={0, -50},
              approach={0, 30},
              timeToLive=0,
              layer="middle",
              variance={
                position={0.25, 0.25},
                size=0.5,
                initialVelocity={10, 10},
                timeToLive=0.2
              }
            }
          }
        }
      }
    }

    for i, a in ipairs(self.projectileParameters.actionOnHit) do
      table.insert(hitscanActionsOnReap, a)
    end
    -- sb.logInfo(self.projectileParameters.hitregPower)
    world.spawnProjectile(
      "invisibleprojectile",
      hitReg[2],
      activeItem.ownerEntityId(),
      self:aimVector(3.14),
      false,
      {
        damageType = "NoDamage",
        power = self.projectileParameters.hitregPower,
        statusEffects = self.projectileParameters.statusEffects,
        timeToLive = 0,
        actionOnReap = hitscanActionsOnReap
      }
    )
end