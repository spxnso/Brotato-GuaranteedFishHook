# Vibe Brotato mods

This repo hosts Vibe's Brotato mods (built for the game's built-in Godot Mod
Loader 6.x, no extra mod libraries required):

- **[Vibe-Vibetato](#vibe-vibetato-brotato-mod)** — run manager: ban presets, forced item spawns per wave, custom boss waves, saved run presets with shareable run codes, wave skip, x2/x3/... speed, per-character loadout templates, starting items (cursed or not)
- **[Vibe-GuaranteedFishHook](#vibe-guaranteedfishhook-brotato-mod)** — guarantees a configurable item in the shop of a configurable wave

---

# Vibe-GuaranteedFishHook (Brotato mod)

Guarantees a configurable item — by default the **Fish Hook** — in the shop of a
configurable wave (default: **wave 5**). Built for Brotato's built-in Godot Mod
Loader (ModLoader 6.x, ships with the game since 1.0.61), no extra mod libraries
required.

> Fish Hook is an **Abyssal Terrors DLC** item (`item_fish_hook`, tier II,
> "+20% chance for locked shop items to become cursed"). You need the DLC
> installed and enabled for the default config to find it.

## How it works

The mod installs one script extension on `res://singletons/item_service.gd` and
overrides `get_player_shop_items(wave, player_index, args)` — the function the
shop (`base_shop.gd :: fill_shop_items`) calls to roll offers. The extension calls
the original, then, if the current wave matches the config, replaces one shop slot
with the configured item (running it through the game's own
`apply_item_effect_modifications`, so tier bumps like Goldfish and curse rolls
behave exactly like a natural shop offer). Slot prices are computed by the game
from the item and wave, so the Fish Hook appears at its normal wave-5 price.

"Wave 5's shop" = the shop shown after finishing wave 5 (the game passes
`RunData.current_wave`, which is still 5 while that shop is open).

## Install

1. Locate the game directory: Steam → Brotato → Manage → Browse local files
   (e.g. `steamapps/common/Brotato`).
2. Copy the folder `mods-unpacked/Vibe-GuaranteedFishHook` from this repo into
   `<game dir>/mods-unpacked/`, so it sits next to any other mods.
3. Start Brotato, open the **Mods** menu, enable **GuaranteedFishHook**, restart
   if asked.
4. Check `logs/modloader.log` in the Brotato user data folder
   (`%APPDATA%/Godot/app_userdata/Brotato/` on Windows,
   `~/.local/share/godot/app_userdata/Brotato/` on Linux) — the mod logs
   `Wave 5 shop: slot N forced to 'item_fish_hook'` when it fires.

To publish on the Steam Workshop instead, zip the contents so that the zip root
contains `mods-unpacked/Vibe-GuaranteedFishHook/...`.

## Configuration

Edit `config.json` inside the mod folder
(`<game dir>/mods-unpacked/Vibe-GuaranteedFishHook/config.json`) and restart the
game. If you installed the mod from the Workshop (read-only location), create
`user://Vibe-GuaranteedFishHook.json` (same JSON, in the user data folder above)
instead — it overrides the bundled `config.json`. All keys are optional; missing
keys fall back to the defaults below.

```json
{
	"enabled": true,
	"wave": 5,
	"waves": [],
	"item_id": "item_fish_hook",
	"slot": "last_item",
	"apply_shop_modifiers": true
}
```

| Key | Default | Meaning |
| --- | --- | --- |
| `enabled` | `true` | Master switch. Set `false` to disable without uninstalling. |
| `wave` | `5` | Wave whose shop gets the guaranteed item (the shop after that wave). |
| `waves` | `[]` | If non-empty, a list of waves, e.g. `[3, 5, 10]`; overrides `wave`. |
| `item_id` | `"item_fish_hook"` | Any item id, e.g. `"item_medikit"`, `"item_mirror"`. |
| `slot` | `"last_item"` | Which shop slot to replace: `"first"`, `"last"`, `"random"` (any slot, incl. weapons) or `"first_item"`, `"last_item"`, `"random_item"` (item slots only, so the guaranteed weapon slots stay untouched). |
| `apply_shop_modifiers` | `true` | Run the forced item through the game's shop modifiers (Goldfish tier bump, curse chance, DLC effects), like a natural offer. Set `false` for the plain item. |

Notes:

- If the item already appears in that shop naturally, nothing is replaced.
- Works per player in co-op; each player's shop roll is patched independently.
- Changing `item_id` makes it a generic "guaranteed item" mod; `wave`/`waves`
  make it a "guaranteed item at wave N" mod.

## Files

```
mods-unpacked/Vibe-GuaranteedFishHook/
├── manifest.json                          ModLoader manifest
├── mod_main.gd                            entry point, installs the extension
├── config.json                            default configuration (edit me)
└── extensions/singletons/item_service.gd  hook on ItemService.get_player_shop_items
```

## Disclaimer

This is a cheat/QoL mod. Brotato has no official mod API for this kind of hook;
the mod uses the community-standard Godot Mod Loader script-extension mechanism
and only contains its own code (no game code). Use at your own risk — it may
break with game updates. Multiplayer/leaderboard runs should not use cheats.

---

# Vibe-Vibetato (Brotato mod)

**Vibetato** is a run manager for Brotato. It lets you script how a run starts
and how its shops and waves behave, save any number of configurations as named
**presets**, and share them with friends as short **run codes**.

Built for Brotato's built-in Godot Mod Loader (ModLoader 6.x), no extra mod
libraries required. It only contains its own code (no game code).

## Features

| Feature | Preset key | How |
| --- | --- | --- |
| Ban presets (items/weapons by id or tier) | `ban_preset`, `banned_items`, `banned_weapons`, `banned_item_tiers`, `banned_weapon_tiers` | Banned shop offers are replaced by a random unbanned offer of the same type |
| Forced item spawns at a given wave | `forced_shop_spawns`: `{"5": ["item_medikit"]}` | The wave-N shop gets the listed items in item slots (optionally through the game's shop modifiers) |
| Boss spawn waves | `boss_waves`: `[10, 20]` | Waves not listed lose their boss groups; listed waves without one get a copy of the vanilla boss group |
| Saved runs / multiple presets | `presets` in the presets file | Named presets stored in `user://Vibe-Vibetato-presets.json`, switchable via `active_preset` |
| Seed sharing & run codes | `seed`, `run_code` | A preset encodes to a `VBT1.…` base64 string; set it as `run_code` to apply it |
| Wave skip | `start_wave`, `starting_gold` | Starts the run at wave N (via `DebugService.starting_wave`), with materials (`starting_gold` or `wave_skip_gold_per_wave × (N-1)`) |
| Fast forward / speed | `speed_multiplier`, hotkey | `Engine.time_scale` x2/x3/x4… at run start, plus a hotkey (default **F9**) to cycle speed mid-run; resets to x1 when the run ends |
| Loadout templates per character | `loadout_templates`: `{"character_well_rounded": {"weapons": [...], "items": [...]}}` | Applied at run start for the picked character |
| Start with a given item, cursed or not | `starting_items`: `[{"id": "item_fish_hook", "cursed": true}]` | Cursed uses the Abyssal Terrors DLC `curse_item` (needs the DLC); otherwise the plain item is added |

## How it works

The mod installs four script extensions:

- `extensions/singletons/item_service.gd` — patches `get_player_shop_items` to
  apply bans and forced per-wave spawns to each player's shop roll.
- `extensions/singletons/run_data.gd` — patches `add_starting_items_and_weapons`
  to add preset starting weapons and per-character loadout templates at run start.
- `extensions/singletons/progress_data.gd` — applies boss-wave selection to the
  zone wave data (`zone.waves_data[i]` = wave `i+1`, `groups_data[].is_boss`).
- `extensions/main.gd` — on run start applies `seed` and `speed_multiplier` and
  hides the panel; on `clean_up_room` shows the panel again and resets the speed
  to x1.
- `src/vibetato_panel.gd` — the [in-game panel](#in-game-panel), attached to the
  scene-tree root by `mod_main.gd`, so it does not depend on the game's menu
  script paths (Brotato 1.2 moved the title screen to `ui/menus/title_screen/`).

Starting **items** (cursed or not) go through the vanilla `DebugService.debug_items`
mechanism, and wave skip through `DebugService.starting_wave` / `starting_gold` /
`instant_waves` — both are (re)applied from the active preset on every state
reload, so switching presets never leaves stale values behind.

Shared state (active preset, config, presets doc) is stored on the `RunData`
autoload under the `vibe_vibetato_state` key and read by every extension.

## Install

1. Locate the game directory: Steam → Brotato → Manage → Browse local files.
2. Copy the folder `mods-unpacked/Vibe-Vibetato` from this repo into
   `<game dir>/mods-unpacked/`.
3. Start Brotato, open the **Mods** menu, enable **Vibetato**, restart if asked.
4. Check `logs/modloader.log` in the Brotato user data folder
   (`%APPDATA%/Godot/app_userdata/Brotato/` on Windows,
   `~/.local/share/godot/app_userdata/Brotato/` on Linux) — the mod logs the
   active preset and its shareable run code at startup.

A ready-to-use Workshop-style archive is in
[`dist/Vibe-Vibetato.zip`](dist/Vibe-Vibetato.zip) (zip root contains
`mods-unpacked/Vibe-Vibetato/...`).

## Configuration

Edit `config.json` inside the mod folder and restart the game. If installed
from the Workshop (read-only location), create `user://Vibe-Vibetato.json`
(same JSON, in the user data folder above) instead — it overrides the bundled
`config.json`. All keys are optional.

```json
{
	"enabled": true,
	"active_preset": "",
	"run_code": "",
	"speed_multiplier": 1.0,
	"speed_steps": [1, 2, 3, 4],
	"hotkey_speed_cycle": "F9",
	"wave_skip_gold_per_wave": 30
}
```

| Key | Default | Meaning |
| --- | --- | --- |
| `enabled` | `true` | Master switch. Set `false` to disable without uninstalling. |
| `active_preset` | `""` | Name of the preset to use (from the presets file). `""` = no preset (vanilla behavior). |
| `run_code` | `""` | A `VBT1.…` run code. Takes priority over `active_preset` — paste a friend's code here. |
| `speed_multiplier` | `1.0` | Global game speed applied at startup (and at run start if the preset sets it). |
| `speed_steps` | `[1, 2, 3, 4]` | Speeds cycled through by the hotkey. |
| `hotkey_speed_cycle` | `"F9"` | Key that cycles `Engine.time_scale` through `speed_steps` mid-run. |
| `wave_skip_gold_per_wave` | `30` | Materials granted per skipped wave when a preset sets `start_wave` without `starting_gold`. |

## In-game panel

Vibetato adds a panel at the **top-right of the screen while in menus** (attached
to the scene-tree root, so game updates that move menu scripts can't break it; it
hides automatically while a run is active). No restart needed — changes apply
immediately and are persisted:

- **Preset** dropdown — lists every preset from the presets file (plus `(none)`
  for vanilla behavior). Selecting one stores it as `active_preset` in
  `user://Vibe-Vibetato.json` and re-applies wave skip, boss waves, speed, etc.
- **Ban** dropdown — picks the `ban_preset` of the currently active named
  preset (written into `user://Vibe-Vibetato-presets.json`).
- **Code** field + **Apply** — paste a `VBT1.…` run code to use it (stored as
  `run_code`, which takes priority over `active_preset`).
- **Copy run code** / **Refresh** — copies the active preset's shareable run code
  to the clipboard (also logged to `modloader.log` at startup), or reloads the
  JSON files from disk.
- **Speed** dropdown — x1/x2/x3/x4 from `speed_steps`; sets
  `Engine.time_scale` immediately and persists `speed_multiplier`. The
  `hotkey_speed_cycle` hotkey (F9) still works in-run.
- **Enabled** checkbox — master switch, persisted as `enabled`.
- Status line shows the active preset, current speed and its run code.

## Presets, ban presets and run codes

Presets live in `presets.default.json` (bundled examples) and can be extended
or overridden in `user://Vibe-Vibetato-presets.json` (same structure; the two
files are merged, user file wins per key). Structure:

```json
{
	"active": "",
	"ban_presets": {
		"no_legendaries": { "item_tiers": [4], "weapon_tiers": [4] }
	},
	"presets": {
		"cursed_fish_hook": {
			"seed": 1337,
			"start_wave": 1,
			"starting_gold": 30,
			"speed_multiplier": 2,
			"instant_waves": false,
			"ban_preset": "no_legendaries",
			"forced_shop_spawns": { "5": ["item_medikit"] },
			"boss_waves": [10, 20],
			"starting_items": [{ "id": "item_fish_hook", "cursed": true }],
			"starting_weapons": ["weapon_spear_1"],
			"loadout_templates": {
				"character_well_rounded": {
					"weapons": ["weapon_spear_1"],
					"items": [{ "id": "item_medikit", "cursed": false }]
				}
			}
		}
	}
}
```

### Preset keys

| Key | Type | Effect |
| --- | --- | --- |
| `seed` | int | RNG seed applied at run start (vanilla uses the global RNG, so this makes runs reproducible). Omit for random. |
| `start_wave` | int | Wave the run starts at (wave skip). `> 1` also sets starting materials. |
| `starting_gold` | int | Starting materials. If omitted with `start_wave > 1`, computed as `wave_skip_gold_per_wave × (start_wave - 1)`. |
| `speed_multiplier` | float | `Engine.time_scale` for the run (x2, x3, …). Clamped to 0.25–8. |
| `instant_waves` | bool | Vanilla debug flag: waves last 1 second (fast forward). |
| `ban_preset` | string | Name of an entry in `ban_presets`. |
| `banned_items` / `banned_weapons` | string[] | Item/weapon ids banned from shops (inline alternative to a ban preset). |
| `banned_item_tiers` / `banned_weapon_tiers` | int[] | Ban whole tiers (4 = legendary). |
| `forced_shop_spawns` | object | `{"<wave>": ["item_id", ...]}` — items forced into that wave's shop. |
| `apply_shop_modifiers` | bool | `true` (default): forced items go through `apply_item_effect_modifications` like natural offers. |
| `boss_waves` | int[] | Waves that keep/spawn boss groups. Default vanilla `[10, 20]` if omitted. |
| `starting_items` | array | `"item_id"` or `{"id": "item_id", "cursed": bool}` — added at run start. Cursed requires the Abyssal Terrors DLC. |
| `starting_weapons` | string[] | Weapon ids added as starting weapons. |
| `loadout_templates` | object | Per-character `{"character_id": {"weapons": [...], "items": [...]}}`. |

### Run codes

Any preset can be shared as a run code: at startup the mod logs
`Share run code: VBT1.…` for the active preset (base64 JSON, prefix `VBT1.`).
To use a code, set `"run_code": "VBT1.…"` in `config.json` /
`user://Vibe-Vibetato.json` and restart. A run code takes priority over
`active_preset`.

## Files

```
mods-unpacked/Vibe-Vibetato/
├── manifest.json                                  ModLoader manifest
├── mod_main.gd                                    entry point: installs extensions, hotkey, state
├── config.json                                    default configuration (edit me)
├── presets.default.json                           bundled ban presets + example presets
├── src/vibetato_core.gd                           config/preset/run-code logic, shared helpers
├── src/vibetato_panel.gd                          in-game panel (attached to the scene root)
└── extensions/
    ├── main.gd                                    seed + speed at run start, panel hide/show, speed reset
    ├── singletons/item_service.gd                 shop bans + forced per-wave spawns
    ├── singletons/progress_data.gd                boss wave selection (on DLC/wave load)
    └── singletons/run_data.gd                     starting weapons + per-character loadout templates
```

## Compatibility

Hook paths were verified against a Brotato **v1.2.0.3** ModLoader log (Godot 3.7
custom build): `singletons/item_service.gd`, `singletons/run_data.gd`,
`main.gd`, `singletons/debug_service.gd` and `singletons/progress_data.gd` are
all still patched by other current mods, and the panel is root-attached so the
1.2 menu refactor (`ui/menus/title_screen/title_screen.gd`) does not affect it.
All GDScript uses plain `=` instead of `:=` everywhere — Godot 3 cannot infer
several `:=` forms (empty literals, `for`-loop counters, Variant-returning
calls), and a single missed `:=` kills the whole mod at parse time, which is
what broke the first two Workshop builds.

## Disclaimer

This is a cheat/QoL mod. Brotato has no official mod API for these hooks; the
mod uses the community-standard Godot Mod Loader script-extension mechanism and
only contains its own code (no game code). Use at your own risk — it may break
with game updates. Always back up your save files before using mods, and start
a fresh run after changing the mod list. Multiplayer/leaderboard runs should
not use cheats.
