extends "res://singletons/run_data.gd"

const Core = preload("res://mods-unpacked/Vibe-Vibetato/src/vibetato_core.gd")
const LOG_NAME := "Vibe-Vibetato:RunData"


func add_starting_items_and_weapons() -> void:
	.add_starting_items_and_weapons()
	if not Core.is_enabled():
		return
	var preset: Dictionary = Core.get_preset()
	if preset.empty():
		return

	for player_index in players_data.size():
		var char_id := Core.get_character_id(player_index)

		var templates: Dictionary = preset.get("loadout_templates", {})
		if char_id != "" and templates.has(char_id):
			var template: Dictionary = templates[char_id]
			for wid in template.get("weapons", []):
				var weapon = Core.find_weapon(String(wid))
				if weapon != null:
					add_weapon(weapon, true)
					ModLoaderLog.info("Loadout template '%s': starting weapon '%s'." % [char_id, wid], LOG_NAME)
				else:
					ModLoaderLog.warning("Loadout template '%s': weapon '%s' not found." % [char_id, wid], LOG_NAME)
			for entry in template.get("items", []):
				_add_preset_item(entry, player_index, char_id)

		for wid in preset.get("starting_weapons", []):
			var weapon = Core.find_weapon(String(wid))
			if weapon != null:
				add_weapon(weapon, true)
				ModLoaderLog.info("Starting weapon '%s' added." % wid, LOG_NAME)
			else:
				ModLoaderLog.warning("Starting weapon '%s' not found." % wid, LOG_NAME)

		for entry in preset.get("starting_items", []):
			_add_preset_item(entry, player_index, "")

	ModLoaderLog.info("Starting items/weapons applied from preset '%s'." % String(preset.get("name", "")), LOG_NAME)


func _add_preset_item(entry, player_index: int, char_id: String) -> void:
	var my_id := ""
	var cursed := false
	if entry is String:
		my_id = entry
	elif entry is Dictionary:
		my_id = String(entry.get("id", ""))
		cursed = bool(entry.get("cursed", false))
	if my_id == "":
		return
	var item = Core.find_item(my_id)
	if item == null:
		ModLoaderLog.warning("Starting item '%s' not found." % my_id, LOG_NAME)
		return
	if cursed:
		var cursed_item = Core.apply_curse(item, player_index)
		if cursed_item != null:
			item = cursed_item
			ModLoaderLog.info("Starting item '%s' cursed." % my_id, LOG_NAME)
		else:
			ModLoaderLog.warning("Cannot curse '%s' (Abyssal Terrors DLC not available); adding it uncursed." % my_id, LOG_NAME)
	Core.add_item_safe(item, player_index)
	var origin := char_id if char_id != "" else String(Core.get_preset().get("name", "preset"))
	ModLoaderLog.info("Starting item '%s' added (%s)." % [my_id, origin], LOG_NAME)
