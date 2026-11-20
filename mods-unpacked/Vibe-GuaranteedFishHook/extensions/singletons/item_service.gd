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
}

var _missing_item_logged := false


func get_player_shop_items(wave: int, player_index: int, args: ItemServiceGetShopItemsArgs) -> Array:
	var offers: Array = .get_player_shop_items(wave, player_index, args)

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

	if _already_offered(offers, target):
		return offers

	var index := _pick_slot(offers, String(cfg.get("slot", "last_item")))
	if index < 0:
		return offers

	var forced = target
	if cfg.get("apply_shop_modifiers", true):
		forced = apply_item_effect_modifications(target, player_index)

	offers[index][0] = forced
	ModLoaderLog.info("Wave %d shop: slot %d forced to '%s' (player %d)." % [wave, index, target.my_id, player_index + 1], LOG_NAME)
	return offers


func _wave_matches(wave: int, cfg: Dictionary) -> bool:
	var waves: Array = cfg.get("waves", [])
	if waves.empty():
		return wave == int(cfg.get("wave", 5))
	for w in waves:
		if int(w) == wave:
			return true
	return false


func _already_offered(offers: Array, target) -> bool:
	for entry in offers:
		if entry[0] is ItemData and entry[0].my_id_hash == target.my_id_hash:
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


func _get_config() -> Dictionary:
	var cfg: Dictionary = DEFAULTS.duplicate(true)
	var paths := [
		ModLoaderMod.get_unpacked_dir().plus_file(MOD_ID + "/config.json"),
		"user://" + MOD_ID + ".json",
	]
	for path in paths:
		var file := File.new()
		if file.open(path, File.READ) != OK:
			continue
		var text := file.get_as_text()
		file.close()
		var parsed := JSON.parse(text)
		if parsed.error != OK or not parsed.result is Dictionary:
			ModLoaderLog.warning("Could not parse config file '%s'." % path, LOG_NAME)
			continue
		for key in parsed.result:
			cfg[key] = parsed.result[key]
	return cfg
