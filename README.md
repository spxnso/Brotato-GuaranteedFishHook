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
