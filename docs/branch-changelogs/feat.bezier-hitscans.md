# New (modders)
- Add support for advanced hitscan VFX:
```jsonc
{
  "hitscanParameters": {
      "vfxParameters": {
        "mode": "bezier",  // "bezier", "lightning", "bezierLightning"
        "segments": 8,
        "controlPointRatio": 0.5,  // only matters if bezier
        "intensity": 1,  // only matters if lightning

        // dictates timing of segment fade-out.
        // If set to 0, all segments fade out at the same time.
        // If set to 1, segments fade out one-by-one; segments closer to origin disappear faster.
        "decay": 0.5,
      }
  }
}
```