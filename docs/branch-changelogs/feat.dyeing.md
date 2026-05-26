- TODO: make vanilla dyes affect project 45 weapons (if a mod does it, great nvm)
- TODO: make dyes affect magazine particles?
# New
- dyeing works now but needs a custom script and items that use that script.

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
  If the "specs" field is empty, defaults to /particles/project45/defaultmagparticle.config. It accepts any JSON file, so you can even link to a .particle file and it'll be applied as is.

  If you still wanna configure the particles via animationCustom, then just omit this field.