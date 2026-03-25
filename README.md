[![](https://img.shields.io/badge/tikrit_1.0-passing-light_green)](https://github.com/gongahkia/tikrit/releases/tag/1.0)
[![](https://img.shields.io/badge/tikrit_2.0-passing-green)](https://github.com/gongahkia/tikrit/releases/tag/2.0)

# `Tikrit`

Top-down cold-weather survival game written in [Lua](https://www.lua.org/) using [Love2D](https://love2d.org/).

## Current Build

`Tikrit` has been reworked from a dungeon survival-horror prototype into a single-region wilderness survival sandbox.

Core loop:

- Scavenge caches and outdoor loot nodes for food, fuel, tinder, cloth, and tools.
- Manage condition, warmth, fatigue, thirst, calories, wetness, carry weight, and frostbite.
- Use cabins, caves, snow shelters, and fires to recover.
- Avoid weak ice, blizzards, and wolves long enough to survive another day.

Run variants:

- `Start Survival`: standard procedural sandbox run.
- `Daily Run`: seeded daily survival run using the same ruleset.
- `Replays`: playback of saved survival and daily runs using replay format `3.0`.

## Controls

- `WASD` or arrow keys: move
- `Left Shift`: sprint
- `E`: interact or scavenge
- `F`: start or feed a fire
- `R`: rest
- `C`: open the craft menu indoors or at a workbench, or build a snow shelter outdoors
- `X`: context action for snares, snow shelters, and curing racks
- `H`: repair clothing
- `T`: auto-treat the highest priority affliction
- `M`: map the nearby terrain at an overlook with charcoal
- `B`: ready or lower the bow
- `Space`: fire a readied bow
- `1-9`: use inventory item
- `Esc`: pause
- `F5`: open the debug world editor from menus
- `F6`: playtest the current editor map

## Usage

```console
$ git clone https://github.com/gongahkia/tikrit && cd tikrit
$ chmod +x install.sh build.sh
$ ./install.sh
$ ./build.sh
$ make
$ make test
```

## Art Status

Retained and repurposed art:

- Existing door, chest, wall, floor, player, tombstone, and bottle sprites remain in use.
- New survival entities now use dedicated placeholder sprite files with stable names in `src/sprite/`.

Still pending for a final art pass:

- Final winter survivor sprite
- Refined terrain set for snow, ice, trees, rocks, and trails
- Cabin/cave prop art
- Final wildlife and item sprites

## Discovery And Audio

- Points of interest are discovered when you directly see them or reveal them with charcoal mapping.
- Discovered POIs show up on the HUD and as simple map labels in-world.
- The runtime now emits stable sound event IDs for survival actions and weather loops, even when a specific audio file is still missing.
- Required audio hooks and filenames are documented in [docs/audio_manifest.md](/Users/gongahkia/Desktop/coding/projects/tikrit/docs/audio_manifest.md).

## Editor Workflow

The in-game editor is now wired into runtime playtests.

- Paint an outdoor layout using the survival tool palette.
- Save and reload maps from `editor_maps/`.
- Press `F6` to launch the current map as a playable run.

Editor symbols map into runtime data for:

- cabins and caves
- weak ice and frozen lakes
- loot nodes
- wolf, rabbit, and deer zones
- snow shelters and player start markers

## Assets

- Reused source sprites originally came from Kenney's [tiny dungeon asset pack](https://kenney.nl/assets/tiny-dungeon)
- Audio from [OpenGameArt](https://opengameart.org/)
- New placeholder survival sprites in `src/sprite/` are project-local prototype assets for this redesign
