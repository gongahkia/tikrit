# Audio Manifest

This pass does not ship placeholder audio. It standardizes the event hooks and expected filenames so assets can be dropped into `src/sound/` without further code changes.

| Event ID | Expected File | Trigger | Type | Notes |
| --- | --- | --- | --- | --- |
| `ambient` | `ambient-background.mp3` | global background ambience from boot | loop | low, cold environmental bed |
| `walking` | `player-walking.mp3` | player movement | loop | muted snow-footstep loop |
| `item_pickup` | `player-collect-item.mp3` | loot/cache gather | one-shot | light pickup tick |
| `player_death` | `player-death.mp3` | death transition | one-shot | short, subdued end sting |
| `door_open` | `door-open.mp3` | cabin door auto-open | one-shot | wood latch / cabin creak |
| `bow_ready` | `bow-ready.mp3` | bow readied | one-shot | cloth/leather draw prep |
| `bow_fire` | `bow-fire.mp3` | arrow loosed | one-shot | bowstring release |
| `arrow_hit` | `arrow-hit.mp3` | successful bow hit | one-shot | soft impact thud |
| `snare_set` | `snare-set.mp3` | snare placed | one-shot | wire/cord tension click |
| `snare_catch` | `snare-catch.mp3` | rabbit collected from trap | one-shot | snare snap / struggle tail |
| `fish_catch` | `fish-catch.mp3` | fish successfully pulled from ice | one-shot | ice splash + line tension |
| `harvest` | `harvest.mp3` | carcass harvested | one-shot | restrained field dressing texture |
| `rope_climb` | `rope-climb.mp3` | rope climb completed | one-shot | exertion + rope friction |
| `map_reveal` | `map-reveal.mp3` | charcoal mapping used | one-shot | charcoal sketch / page brush |
| `craft` | `craft.mp3` | recipe or snow shelter crafted | one-shot | short utility crafting blend |
| `treat` | `treat.mp3` | treatment consumed/applied | one-shot | cloth wrap / bottle / tablet cue |
| `poi_discovery` | `poi-discovery.mp3` | first-time POI discovery | one-shot | subtle navigation sting |
| `weather_wind_loop` | `weather-wind-loop.mp3` | windy weather active | loop | should layer under ambient |
| `weather_blizzard_loop` | `weather-blizzard-loop.mp3` | blizzard weather active | loop | denser, harsher storm layer |

Implementation notes:

- Missing files are safe no-ops through `src/modules/sound_events.lua`.
- Weather loops are exclusive: `wind` and `blizzard` should not play simultaneously.
- New assets should be mixed conservatively; `ambient` and weather loops share the music volume slider, while action sounds use SFX volume.
