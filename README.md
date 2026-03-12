[![](https://img.shields.io/badge/tikrit_1.0-passing-light_green)](https://github.com/gongahkia/tikrit/releases/tag/1.0)
[![](https://img.shields.io/badge/tikrit_2.0-passing-green)](https://github.com/gongahkia/tikrit/releases/tag/2.0)

# Tikrit

![](asset/tikrit-origin.png)

Tiny survival-horror [roguelike](https://en.wikipedia.org/wiki/Roguelike) written in [Lua](https://www.lua.org/) using Love2D.

This branch uses a procgen-only game flow with:

- typed enemy archetypes
- a persisted settings screen
- a sanity system tied to dark zones, safe rooms, and enemy pressure

## Installation

### Local Run

```console
$ git clone https://github.com/gongahkia/tikrit
$ ./install.sh
$ make
```

### Tests

```console
$ make test
```

### Build

```console
$ ./build.sh
```

This produces `dist/tikrit-<version>.love`.

## Assets

- Sprites from Kenney's [tiny dungeon](https://kenney.nl/assets/tiny-dungeon) asset pack
- Audio from [OpenGameArt](https://opengameart.org/)
