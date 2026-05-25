- [ ] TODO: apply laser changes to alt laser too (military flashlight, scopes)
# New (modders)
- Primary laser start points can now be offset via the 'laser.offset' parameter.
  - 'laser.offset' can be a 2d vector array or a string corresponding to the visual part of the weapon ("rail", "sight", "underbarrel")
  - If 'laser.offset' is a visual part, you can use 'laser.offsetAdd', which MUST be a 2d vector array and is added to the visual part's offset. Otherwise, 'laser.offsetAdd' is irrelevant. Useful for fine-adjusting.
- Can specify if laser still points to actual impact location via 'laser.alwaysZeroed'. Warning: Enabling this setting with a far enough offset may lead to weird-looking (read: diagonal) lasers. Irrelevant when 'laser.offset' is a zero vector or basically the muzzle.
- Primary laser layer can now be set to make it appear over or under a weapon (default "Player-2", refer to lua entity layers)

# Changes (modders)
- Added a new parameter 'offsetAdd' to 'hitscanLib:hitscan()' right after the 'offset' parameter.