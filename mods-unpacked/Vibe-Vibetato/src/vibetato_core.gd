const MOD_ID = "Vibe-Vibetato"
const LOG_NAME = "Vibe-Vibetato"
const STATE_KEY = "vibe_vibetato_state"
const RUN_CODE_PREFIX = "VBT1."

const DEFAULT_CONFIG = {
	"enabled": true,
	"active_preset": "",
	"run_code": "",
	"speed_multiplier": 1.0,
	"speed_steps": [1, 2, 3, 4],
	"hotkey_speed_cycle": "F9",
	"wave_skip_gold_per_wave": 30,
	"default_starting_gold": 30,
}


static func mod_dir() -> String:
	return ModLoaderMod.get_unpacked_dir().plus_file(MOD_ID)


static func get_state() -> Dictionary:
	var s = RunData.get(STATE_KEY)
	if s == null or not s is Dictionary:
		return {}
	return s


static func get_config() -> Dictionary:
	return get_state().get("config", {})


static func get_preset() -> Dictionary:
	return get_state().get("preset", {})


static func get_presets_doc() -> Dictionary:
	return get_state().get("presets_doc", {})


static func is_enabled() -> bool:
	return get_state().get("enabled", true)


static func load_json_file(path: String) -> Dictionary:
	var f = File.new()
	if f.open(path, File.READ) != OK:
		return {}
	var text = f.get_as_text()
	f.close()
	var parsed = JSON.parse(text)
	if parsed.error != OK or not parsed.result is Dictionary:
		return {}
	return parsed.result


static func load_config() -> Dictionary:
	var cfg: Dictionary = DEFAULT_CONFIG.duplicate(true)
	var paths: Array = [mod_dir().plus_file("config.json"), "user://" + MOD_ID + ".json"]
	for path in paths:
		var data = load_json_file(path)
		for k in data:
			cfg[k] = data[k]
	return cfg


static func load_presets_doc() -> Dictionary:
	var doc = load_json_file(mod_dir().plus_file("presets.default.json"))
	if doc.empty():
		doc = {"ban_presets": {}, "presets": {}}
	var user_doc = load_json_file("user://" + MOD_ID + "-presets.json")
	var ban_a: Dictionary = doc.get("ban_presets", {})
	var ban_b: Dictionary = user_doc.get("ban_presets", {})
	for k in ban_b:
		ban_a[k] = ban_b[k]
	doc["ban_presets"] = ban_a
	var pres_a: Dictionary = doc.get("presets", {})
	var pres_b: Dictionary = user_doc.get("presets", {})
	for k in pres_b:
		pres_a[k] = pres_b[k]
	doc["presets"] = pres_a
	if user_doc.has("active"):
		doc["active"] = user_doc["active"]
	return doc


static func resolve_active_preset(cfg: Dictionary, doc: Dictionary) -> Dictionary:
	var run_code: String = String(cfg.get("run_code", "")).strip_edges()
	if run_code != "":
		var p = decode_run_code(run_code)
		if not p.empty():
			p["name"] = "run_code"
			return p
		ModLoaderLog.warning("Could not decode run_code, falling back to active_preset.", LOG_NAME)
	var active: String = String(cfg.get("active_preset", ""))
	if active == "" and doc.has("active"):
		active = String(doc.get("active", ""))
	var presets: Dictionary = doc.get("presets", {})
	if active != "" and presets.has(active):
		var preset: Dictionary = presets[active].duplicate(true)
		preset["name"] = active
		return preset
	if cfg.has("preset") and cfg["preset"] is Dictionary and not cfg["preset"].empty():
		return cfg["preset"]
	return {}


static func encode_run_code(preset: Dictionary) -> String:
	var copy = preset.duplicate(true)
	copy.erase("name")
	return RUN_CODE_PREFIX + Marshalls.raw_to_base64(JSON.print(copy, "", true).to_utf8())


static func decode_run_code(code: String) -> Dictionary:
	var c = code.strip_edges()
	if not c.begins_with(RUN_CODE_PREFIX):
		return {}
	var raw = Marshalls.base64_to_raw(c.substr(RUN_CODE_PREFIX.length()))
	if raw.empty():
		return {}
	var parsed = JSON.parse(raw.get_string_from_utf8())
	if parsed.error != OK or not parsed.result is Dictionary:
		return {}
	return parsed.result


static func reload_state() -> void:
	var cfg = load_config()
	var doc = load_presets_doc()
	var preset = resolve_active_preset(cfg, doc)
	var enabled: bool = cfg.get("enabled", true)
	RunData.set(STATE_KEY, {
		"enabled": enabled,
		"config": cfg,
		"preset": preset,
		"presets_doc": doc,
	})
	apply_preset_to_debug_service()
	if not enabled:
		Engine.time_scale = 1.0
		ModLoaderLog.info("Disabled via config.", LOG_NAME)
		return
	apply_boss_waves_from_preset()
	Engine.time_scale = float(cfg.get("speed_multiplier", 1.0))
	if not preset.empty():
		ModLoaderLog.info("Active preset: '%s'." % String(preset.get("name", "")), LOG_NAME)
		ModLoaderLog.info("Share run code: %s" % encode_run_code(preset), LOG_NAME)


static func find_item(my_id: String):
	var el = ItemService.get_element(ItemService.items, my_id)
	if el == null:
		el = ItemService.get_element(ItemService.items, Keys.generate_hash(my_id))
	if el == null:
		var short = my_id.trim_prefix("item_")
		var dlc_path = "res://dlcs/dlc_1/items/%s/%s_data.tres" % [short, short]
		if ResourceLoader.exists(dlc_path):
			el = load(dlc_path)
	return el


static func find_weapon(my_id: String):
	var el = ItemService.get_element(ItemService.weapons, my_id)
	if el == null:
		el = ItemService.get_element(ItemService.weapons, Keys.generate_hash(my_id))
	return el


static func get_character_id(player_index: int) -> String:
	var c = RunData.get_player_character(player_index)
	if c == null:
		return ""
	return String(c.get("my_id"))


static func _has_method(obj, method_name: String) -> bool:
	for m in obj.get_method_list():
		if m["name"] == method_name:
			return true
	return false


static func apply_curse(item_data, player_index: int):
	for dlc_data in ProgressData.available_dlcs:
		if _has_method(dlc_data, "curse_item"):
			return dlc_data.curse_item(item_data, player_index, true)
	return null


static func add_item_safe(item, player_index: int) -> void:
	var argc = -1
	for m in RunData.get_method_list():
		if m["name"] == "add_item":
			argc = m["args"].size()
			break
	if argc >= 2:
		RunData.add_item(item, player_index)
	else:
		RunData.add_item(item)


static func get_ban_list(preset: Dictionary) -> Dictionary:
	var ban: Dictionary = {
		"items": [],
		"weapons": [],
		"item_tiers": [],
		"weapon_tiers": [],
	}
	var doc = get_presets_doc()
	var ban_presets: Dictionary = doc.get("ban_presets", {})
	var bp_name: String = String(preset.get("ban_preset", ""))
	if bp_name != "" and ban_presets.has(bp_name):
		_merge_ban(ban, ban_presets[bp_name])
	_merge_ban(ban, preset)
	return ban


static func _merge_ban(ban: Dictionary, src) -> void:
	if not src is Dictionary:
		return
	var map: Dictionary = {
		"banned_items": "items",
		"items": "items",
		"banned_weapons": "weapons",
		"weapons": "weapons",
		"banned_item_tiers": "item_tiers",
		"item_tiers": "item_tiers",
		"banned_weapon_tiers": "weapon_tiers",
		"weapon_tiers": "weapon_tiers",
	}
	for k in map:
		if src.has(k) and src[k] is Array:
			for v in src[k]:
				if not ban[map[k]].has(v):
					ban[map[k]].push_back(v)


static func ban_list_empty(ban: Dictionary) -> bool:
	return ban["items"].empty() and ban["weapons"].empty() and ban["item_tiers"].empty() and ban["weapon_tiers"].empty()


static func is_banned(data, ban: Dictionary) -> bool:
	if data == null:
		return false
	var id = ""
	if data.get("my_id") != null:
		id = String(data.get("my_id"))
	elif data.get("weapon_id") != null:
		id = String(data.get("weapon_id"))
	var tier = int(data.get("tier", 0))
	if data is ItemData:
		return ban["items"].has(id) or ban["item_tiers"].has(tier)
	if data is WeaponData:
		return ban["weapons"].has(id) or ban["weapon_tiers"].has(tier)
	return false


static func is_offered(offers: Array, item) -> bool:
	if item == null:
		return false
	for entry in offers:
		if entry[0] == item:
			return true
		if entry[0] != null and entry[0].get("my_id_hash") != null and entry[0].get("my_id_hash") == item.get("my_id_hash"):
			return true
	return false


static func random_unbanned_replacement(data, ban: Dictionary, offers: Array):
	var pool: Array = []
	var src: Array = ItemService.items if data is ItemData else ItemService.weapons
	for el in src:
		if not is_banned(el, ban) and not is_offered(offers, el):
			pool.push_back(el)
	if pool.empty():
		return null
	return pool[randi() % pool.size()]


static func apply_preset_to_debug_service() -> void:
	if not is_enabled():
		DebugService.starting_wave = 1
		DebugService.starting_gold = 30
		DebugService.instant_waves = false
		DebugService.debug_items = []
		return
	var preset: Dictionary = get_preset()
	if preset.has("start_wave") and int(preset["start_wave"]) > 1:
		var w = int(preset["start_wave"])
		DebugService.starting_wave = w
		if preset.has("starting_gold"):
			DebugService.starting_gold = int(preset["starting_gold"])
		else:
			var per_wave = int(get_config().get("wave_skip_gold_per_wave", 30))
			DebugService.starting_gold = per_wave * (w - 1)
		ModLoaderLog.info("Wave skip: starting at wave %d with %d materials." % [w, DebugService.starting_gold], LOG_NAME)
	else:
		DebugService.starting_wave = 1
		DebugService.starting_gold = int(get_config().get("default_starting_gold", 30))
	DebugService.instant_waves = bool(preset.get("instant_waves", false))
	if DebugService.instant_waves:
		ModLoaderLog.info("Instant waves enabled (waves last 1 second).", LOG_NAME)
	var items = _starting_items_data(preset)
	DebugService.debug_items = items
	if not items.empty():
		ModLoaderLog.info("Starting items queued: %s" % str(preset.get("starting_items", [])), LOG_NAME)


static func _starting_items_data(preset: Dictionary) -> Array:
	var items: Array = []
	for entry in preset.get("starting_items", []):
		var my_id = ""
		var cursed = false
		if entry is String:
			my_id = entry
		elif entry is Dictionary:
			my_id = String(entry.get("id", ""))
			cursed = bool(entry.get("cursed", false))
		if my_id == "":
			continue
		var item = find_item(my_id)
		if item == null:
			ModLoaderLog.warning("Starting item '%s' not found." % my_id, LOG_NAME)
			continue
		if cursed:
			var cursed_item = apply_curse(item, 0)
			if cursed_item != null:
				item = cursed_item
				ModLoaderLog.info("Starting item '%s' cursed." % my_id, LOG_NAME)
			else:
				ModLoaderLog.warning("Cannot curse '%s' (Abyssal Terrors DLC missing); adding it uncursed." % my_id, LOG_NAME)
		items.push_back(item)
	return items


static func set_panel_visible(v: bool) -> void:
	var p = RunData.get("vibe_vibetato_panel")
	if p != null:
		p.visible = v


static func apply_boss_waves_from_preset() -> void:
	if not is_enabled():
		return
	var preset = get_preset()
	if not preset.has("boss_waves"):
		return
	var boss_waves: Array = []
	for w in preset["boss_waves"]:
		boss_waves.push_back(int(w))
	var changed = 0
	for dlc in ProgressData.available_dlcs:
		for zone in dlc.zones:
			var waves_data: Array = zone.waves_data
			var boss_template = _find_boss_group(waves_data)
			for i in waves_data.size():
				var wave = waves_data[i]
				var wave_num = i + 1
				var should_be_boss = boss_waves.has(wave_num)
				var had_boss_group = false
				for group in wave.groups_data:
					if group.get("is_boss") == true:
						had_boss_group = true
					if not should_be_boss and group.get("is_boss") == true:
						group.is_boss = false
						changed += 1
				if should_be_boss and not had_boss_group and boss_template != null:
					wave.groups_data.push_back(boss_template.duplicate(true))
					changed += 1
	ModLoaderLog.info("Boss waves set to %s (%d wave group flags changed)." % [str(boss_waves), changed], LOG_NAME)


static func _find_boss_group(waves_data: Array):
	for wave in waves_data:
		for group in wave.groups_data:
			if group.get("is_boss") == true:
				return group
	return null


static func list_preset_names() -> Array:
	var names: Array = []
	var presets: Dictionary = get_presets_doc().get("presets", {})
	for k in presets:
		names.push_back(String(k))
	names.sort()
	return names


static func active_preset_name() -> String:
	return String(get_preset().get("name", ""))


static func speed_steps() -> Array:
	return get_config().get("speed_steps", [1, 2, 3, 4])


static func persist_config(updates: Dictionary) -> void:
	var path = "user://" + MOD_ID + ".json"
	var data = load_json_file(path)
	for k in updates:
		data[k] = updates[k]
	var f = File.new()
	if f.open(path, File.WRITE) != OK:
		ModLoaderLog.error("Could not write config file '%s'." % path, LOG_NAME)
		return
	f.store_string(JSON.print(data, "\t", true))
	f.close()


static func set_preset_field(preset_name: String, key: String, value) -> void:
	var path = "user://" + MOD_ID + "-presets.json"
	var doc = load_json_file(path)
	if not doc.has("presets"):
		doc["presets"] = {}
	var presets: Dictionary = doc["presets"]
	if not presets.has(preset_name):
		presets[preset_name] = {}
	var p: Dictionary = presets[preset_name]
	p[key] = value
	var f = File.new()
	if f.open(path, File.WRITE) != OK:
		ModLoaderLog.error("Could not write presets file '%s'." % path, LOG_NAME)
		return
	f.store_string(JSON.print(doc, "\t", true))
	f.close()
	reload_state()


static func clear_preset() -> void:
	persist_config({"active_preset": "", "run_code": ""})
	reload_state()
	ModLoaderLog.info("Preset cleared (vanilla behavior).", LOG_NAME)


static func apply_preset_by_name(name: String) -> bool:
	var presets: Dictionary = get_presets_doc().get("presets", {})
	if not presets.has(name):
		ModLoaderLog.warning("Preset '%s' not found." % name, LOG_NAME)
		return false
	persist_config({"active_preset": name, "run_code": ""})
	reload_state()
	ModLoaderLog.info("Preset '%s' applied." % name, LOG_NAME)
	return true


static func apply_run_code(code: String) -> bool:
	var preset = decode_run_code(code)
	if preset.empty():
		ModLoaderLog.warning("Invalid run code.", LOG_NAME)
		return false
	persist_config({"run_code": code.strip_edges()})
	reload_state()
	ModLoaderLog.info("Run code applied.", LOG_NAME)
	return true


static func set_enabled(enabled: bool) -> void:
	persist_config({"enabled": enabled})
	reload_state()


static func set_speed(speed: float) -> void:
	Engine.time_scale = speed
	persist_config({"speed_multiplier": speed})
	reload_state()


static func cycle_speed() -> float:
	var cfg = get_config()
	var steps: Array = cfg.get("speed_steps", [1, 2, 3, 4])
	if steps.empty():
		steps = [1, 2, 3, 4]
	var cur = Engine.time_scale
	var idx = 0
	for i in steps.size():
		if float(steps[i]) == cur:
			idx = i
	var next: float = float(steps[(idx + 1) % steps.size()])
	Engine.time_scale = next
	ModLoaderLog.info("Speed multiplier: x%s." % str(next), LOG_NAME)
	return next
