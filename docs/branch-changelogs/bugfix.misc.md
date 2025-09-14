# New
- Added the Project 45 catalog; can be bought in the Project 45 Gun Shop

# Changes
- Improved the Project 45 Manual codex.
- Halved price of the Supply Transponder (Gacha puller) and both kinds of Cipher Keys (Gacha tickets).
- Added Cipher Keys to the drop tables
- Removed stray crafting recipe from the Gunsmith Addon

- Decreased sell factor of the Reimburser from 1x to 0.8x.
- Added increased selling prices for particular items sold via the Reimburser:
  - reagents
  - Unique Project 45 Items

- Balanced the effects of Ammo Consume Chance; If a gun fails to consume ammo, then it will consume exactly 1 energy or 1 stocked ammo.

# New (modders)
- Add 'jamChanceMult' to modifiable stats
- Add checks for gun modifications:
```json
{
  "augment": {
    "gun": {
      "primaryAbility": {
        "manualFeed": {
          "checks": [
            {
              "path": "primaryAbility.semi",
              "operation": "!=",
              "value": false
            }
          ],
          "operation": "replace",
          "value": true
        },
        "jamChanceMult": [
          {
            "operation": "add",
            "value": -0.5
          },
          {
            "checks": [
              {
                "path": "primaryAbility.semi",
                "operation": "!=",
                "value": false,
                "next": "or"
              },
              {
                "path": "primaryAbility.autoChargeAfterFire",
                "operation": "!=",
                "value": true
              }
            ],
            "operation": "add",
            "value": 0.2
          }
        ]
      }
    }
  }
}
```