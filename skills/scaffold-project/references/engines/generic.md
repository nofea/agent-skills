# Other engines

Use this for engines and frameworks without their own reference, such as Defold, LÖVE, Phaser, raylib, GameMaker or a custom engine.

Start from the language reference, if the engine is built on a language this skill covers. Phaser uses [typescript.md](../languages/typescript.md) as a web app, and raylib uses [cpp.md](../languages/cpp.md). Otherwise, use [languages/generic.md](../languages/generic.md).

Look up the engine's own documentation for these. Say which source you used, and mark anything you couldn't confirm as `unverified`.

| Question | What it fills |
| --- | --- |
| Is there a project template or a command-line init? | Init and layout |
| Does it build without a window or GPU? | `build`, `release` |
| Does it have a test runner with a command line? | `test` |
| Can its shipped build run headless and exit by itself? | `test-release`, following [Shipped-build smoke test](../project-types.md#shipped-build-smoke-test) |
| What files are generated? | `.gitignore`, scanner extras |
| What binary files does it use? | `.gitattributes` |
| Can it run in devenv and a Linux container, or does it need a licence? | devenv and CI, using [unity.md](unity.md) as the pattern for licensed editors |

If a verb can't be filled, write a recipe that prints why, and list it in the hand-off. Never make a recipe pass by doing nothing without saying so.
