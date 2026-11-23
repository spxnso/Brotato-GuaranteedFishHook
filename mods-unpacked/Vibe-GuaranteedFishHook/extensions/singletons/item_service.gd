extends "res://singletons/item_service.gd"

const MOD_ID := "Vibe-GuaranteedFishHook"
const LOG_NAME := "Vibe-GuaranteedFishHook:ItemService"

const DEFAULTS := {
	"enabled": true,
	"wave": 5,
	"waves": [],
	"item_id": "item_fish_hook",
	"slot": "last_item",
	"apply_shop_modifiers": true,
	"force_cursed": true,
	"force_once_per_wave": true,
}

var _missing_item_logged := false
var _forced_keys := {}
var _last_wave := 0


func get_player_shop_items(wave: int, player_index: int, args: ItemServiceGetShopItemsArgs) -> Array:
	var offers: Array = .get_player_shop_items(wave, player_index, args)

	# Track wave progression on every shop roll, BEFORE any early return, so
	# a new run always clears the once-per-wave memory. The _last_wave guard
	# keeps wave-1 rerolls (same _last_wave == 1) from re-clearing mid-shop.
	if wave < _last_wave or (wave == 1 and _last_wave != 1):
		if not _forced_keys.empty():
			ModLoaderLog.info("New run detected (wave %d): cleared forced-slot memory." % wave, LOG_NAME)
		_forced_keys.clear()
	_last_wave = wave

	var cfg := _get_config()
	if not cfg.get("enabled", true):
		return offers
	if not _wave_matches(wave, cfg):
		return offers

	var target = _get_target_item(String(cfg.get("item_id", "item_fish_hook")))
	if target == null:
		if not _missing_item_logged:
			_missing_item_logged = true
			ModLoaderLog.error("Item '%s' not found. item_fish_hook needs the Abyssal Terrors DLC. Shop left unchanged." % String(cfg.get("item_id", "")), LOG_NAME)
		return offers

	var key = str(wave) + ":" + str(player_index)
	if cfg.get("force_once_per_wave", true) and _forced_keys.has(key):
		return offers

	# Guarantee the item appears exactly once in this shop: replace any extra
	# natural occurrences with a random other offer of the same type, then
	# force the item into a single configured slot.
	var dupe_slots = []
	for i in offers.size():
		var d = offers[i][0]
		if d != null and d.get("my_id_hash") == target.my_id_hash:
			dupe_slots.push_back(i)

	var index := _pick_slot(offers, String(cfg.get("slot", "last_item")))
	if index < 0:
		return offers

	for i in dupe_slots:
		if i != index:
			var repl = _random_replacement(offers[i][0], target, offers)
			if repl != null:
				offers[i][0] = repl

	var forced = target
	if cfg.get("apply_shop_modifiers", true):
		forced = apply_item_effect_modifications(target, player_index)

	if cfg.get("force_cursed", true) and "cursed" in forced:
		forced = forced.duplicate()
		forced.cursed = true

	offers[index][0] = forced
	_forced_keys[key] = true
	var cursed_note: String = " cursed" if forced.get("cursed") else ""
	ModLoaderLog.info("Wave %d shop: slot %d forced to '%s'%s (player %d)." % [wave, index, target.my_id, cursed_note, player_index + 1], LOG_NAME)
	return offers


func _wave_matches(wave: int, cfg: Dictionary) -> bool:
	var waves: Array = cfg.get("waves", [])
	if waves.empty():
		return wave == int(cfg.get("wave", 5))
	for w in waves:
		if int(w) == wave:
			return true
	return false


func _get_config() -> Dictionary:
	var cfg: Dictionary = DEFAULTS.duplicate(true)

	# Lowest to highest precedence:
	# 1) Bundled config.json shipped with the mod
	# 2) Config managed by dami-ModOptions / ModLoaderConfig (in-game edits)
	# 3) Manual override file user://Vibe-GuaranteedFishHook.json
	_merge_file_into(ModLoaderMod.get_unpacked_dir().plus_file(MOD_ID + "/config.json"), cfg)

	var mod_cfg = ModLoaderConfig.get_current_config(MOD_ID)
	if mod_cfg != null and mod_cfg.data is Dictionary:
		for key in mod_cfg.data:
			cfg[key] = mod_cfg.data[key]

	_merge_file_into("user://" + MOD_ID + ".json", cfg)
	return cfg


func _merge_file_into(path: String, cfg: Dictionary) -> void:
	var file := File.new()
	if file.open(path, File.READ) != OK:
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse(text)
	if parsed.error != OK or not parsed.result is Dictionary:
		ModLoaderLog.warning("Could not parse config file '%s'." % path, LOG_NAME)
		return
	for key in parsed.result:
		cfg[key] = parsed.result[key]


func _random_replacement(data, target, offers: Array):
	var pool: Array = items if data is ItemData else weapons
	var candidates = []
	for el in pool:
		if el.get("my_id_hash") == target.get("my_id_hash"):
			continue
		if _offered(offers, el):
			continue
		candidates.push_back(el)
	if candidates.empty():
		return null
	return candidates[randi() % candidates.size()]


func _offered(offers: Array, el) -> bool:
	for entry in offers:
		if entry[0] != null and entry[0].get("my_id_hash") == el.get("my_id_hash"):
			return true
	return false


func _pick_slot(offers: Array, mode: String) -> int:
	if offers.empty():
		return -1
	var item_slots := []
	for i in offers.size():
		if offers[i][0] is ItemData:
			item_slots.push_back(i)
	if mode == "first":
		return 0
	if mode == "last":
		return offers.size() - 1
	if mode == "random":
		return randi() % offers.size()
	if mode == "first_item":
		if item_slots.empty():
			return 0
		return item_slots[0]
	if mode == "random_item":
		if item_slots.empty():
			return offers.size() - 1
		return item_slots[randi() % item_slots.size()]
	if mode == "last_item":
		if item_slots.empty():
			return offers.size() - 1
		return item_slots[item_slots.size() - 1]
	return offers.size() - 1


func _get_target_item(my_id: String):
	var id_hash := Keys.generate_hash(my_id)
	for item in items:
		if item.my_id_hash == id_hash:
			return item
	var short := my_id.trim_prefix("item_")
	var dlc_path := "res://dlcs/dlc_1/items/%s/%s_data.tres" % [short, short]
	if ResourceLoader.exists(dlc_path):
		return load(dlc_path)
	return null
