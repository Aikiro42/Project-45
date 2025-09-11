# New
- Changed tracer rendering method for almost all projectiles. Instead of spawning a streak particle of static length, projectiles now use a script that draw a streak particle from their previous position to their current position.
- Changed sprite used by almost all bullets, arrows and other projectiles into an animated one; The above change causes projectiles fired by other entities to not have streaks, so the sprites were improved to look good even without the streaks.
- Added distinct projectile sprites for the bladed, explosive, elec and poison arrows.
# Balance
- Added a random speed modifier (mean = 1, st. dev = 0.1) to projectiles fired from guns, improving how they look.
- decreased project45splitblade projectile speed from 150 to 100
- increased project45splitblade time to live from 0.05s to 0.1s
- decreased project45splitbladefragment speed from 150 to 90