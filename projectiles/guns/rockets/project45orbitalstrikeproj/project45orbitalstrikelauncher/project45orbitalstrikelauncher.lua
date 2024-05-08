require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.periodicProjectile = projectile.getParameter("periodicProjectile")
  if self.periodicProjectile then
    self.periodicProjectile.frequency = self.periodicProjectile.frequency or 0.5
  end
  self.projectileSpawnLimit = projectile.getParameter("projectileSpawnLimit", -1)
  self.spawnTimer = 0
end

function update(dt)

  if not self.periodicProjectile then
    sb.logInfo("missing params")
    projectile.die()

  else

    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.periodicProjectile.frequency then
      self.spawnTimer = 0
      world.spawnProjectile(
        self.periodicProjectile.projectileType,
        mcontroller.position(),
        projectile.sourceEntity(),
        vec2.rotate({0, -1}, sb.nrand(util.toRadians(self.periodicProjectile.deviation), 0)),
        false, self.periodicProjectile.projectileParameters)
      self.projectileSpawnLimit = self.projectileSpawnLimit - 1
    end

    if self.projectileSpawnLimit == 0 then
      projectile.die()
      return
    end

  end

end
