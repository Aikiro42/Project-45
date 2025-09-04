- add ability to set custom per-setting checks when applying gun modifications
- add project45util.checkJson()
- added a way for mod application to check for weapon's parameters. Syntax is as follows:
  ```json
  // .augment file
  {
    // ...,
    "augment": {
      "checks": [
        {
          "path": "path/from/root/to/primitive",
          "comp": "<",
          "value": 69,
          "next": "or" // optional, "and" by default
        }, // ...
      ],
      // ...
    },
    // ...
  }
  ```
