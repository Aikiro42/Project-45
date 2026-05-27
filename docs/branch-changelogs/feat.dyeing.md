- TODO: make vanilla dyes affect project 45 weapons (if a mod does it, great nvm)
# New
- dyeing works now but needs a custom script and items that use that script.
- The Solarium Alloy mod can now change a weapon's color (if the weapon is properly configured)
- Added new dyes to the shops under the "Util" section.

# Changes
- Changed how certain guns spawn magazine particles on reload.

# New (Modders)
- you can now set magazine particles differently in a way that they're affected by the palette swaps:
  ```
  "magazineParticles": [
    {
      "image": "/path/to/image.png"
      "specs": "/path/to/particlespecs.json"
    },
    {
      "image": "/path/to/image.png"
      "specs": "/path/to/particlespecs.json"
    },
    ...
  ]
  ```
  If the "specs" field is empty, defaults to /particles/project45/defaultmagparticle.config. It accepts any JSON file, so you can even link to a .particle file (as "/path/to/my.particle:definition") and it'll be applied as is.

  If you still wanna configure the particles via animationCustom, then just omit this field.
- You can now make gun mods dye the weapon by configuring their 'augment.dyeColorIndex' field.
- You can now make guns undyeable (and not use palette swaps at all) by setting their "disallowDyeing" parameter to true. See project45-gov-fleetlyfading

# Changes (Modders)
- Moved around some magazine particle files, particularly:
  - project45boneshootermag
  - project45magmaspittermag