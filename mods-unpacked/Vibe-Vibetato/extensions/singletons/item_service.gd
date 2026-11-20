extends "res://singletons/item_service.gd"

const Core = preload("res://mods-unpacked/Vibe-Vibetato/src/vibetato_core.gd")
const LOG_NAME = "Vibe-Vibetato:ItemService"


func get_player_shop_items(wave: int, player_index: int, args: ItemServiceGetShopItemsArgs) -> Array:
	var offers: Array = .get_player_shop_items(wave, player_index, args)
	if not Core.is_enabled():
		return offers
	var preset: Dictionary = Core.get_preset()
	if preset.empty():
		return offers

	offers = _apply_bans(offers, wave, preset)
	offers = _apply_forced_spawns(offers, wave, player_index, preset)
	return offers


func _apply_bans(offers: Array, wave: int, preset: Dictionary) -> Array:
	var ban = Core.get_ban_list(preset)
	if Core.ban_list_empty(ban):
		return offers
	for i in offers.size():
		var data = offers[i][0]
		if Core.is_banned(data, ban):
			var old_id = String(data.get("my_id") if data.get("my_id") != null else data.get("weapon_id"))
			var repl = Core.random_unbanned_replacement(data, ban, offers)
			if repl != null:
				offers[i][0] = repl
				ModLoaderLog.info("Wave %d shop: banned '%s' replaced by '%s'." % [wave, old_id, String(repl.get("my_id"))], LOG_NAME)
			else:
				ModLoaderLog.warning("Wave %d shop: banned '%s' but no unbanned replacement found." % [wave, old_id], LOG_NAME)
	return offers


func _apply_forced_spawns(offers: Array, wave: int, player_index: int, preset: Dictionary) -> Array:
	var forced_map: Dictionary = preset.get("forced_shop_spawns", {})
	if forced_map.empty() or not forced_map.has(str(wave)):
		return offers
	var forced: Array = forced_map[str(wave)]
	if forced.empty():
		return offers
	var item_slots: Array = []
	for i in offers.size():
		if offers[i][0] is ItemData:
			item_slots.push_back(i)
	if item_slots.empty():
		return offers
	var slot_idx = 0
	for entry in forced:
		var my_id = String(entry)
		var item = Core.find_item(my_id)
		if item == null:
			ModLoaderLog.warning("Wave %d: forced item '%s' not found." % [wave, my_id], LOG_NAME)
			continue
		if Core.is_offered(offers, item):
			continue
		var index: int = item_slots[slot_idx % item_slots.size()]
		slot_idx += 1
		if bool(preset.get("apply_shop_modifiers", true)):
			offers[index][0] = apply_item_effect_modifications(item, player_index)
		else:
			offers[index][0] = item
		ModLoaderLog.info("Wave %d shop: slot %d forced to '%s' (player %d)." % [wave, index, my_id, player_index + 1], LOG_NAME)
	return offers
