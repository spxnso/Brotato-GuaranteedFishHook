extends Node

const MOD_ID := "Vibe-GuaranteedFishHook"
const MOD_DIR_NAME := MOD_ID

const DEFAULT_SETTINGS := {
	"enabled": true,
	"wave": 5,
	"waves": [],
	"item_id": "item_fish_hook",
	"slot": "last_item",
	"apply_shop_modifiers": true,
	"force_once_per_wave": true,
}

var _version = "1.0.0"


func _init() -> void:
	ModLoaderLog.info("Initialized.", MOD_ID)
	var mod_dir_path = ModLoaderMod.get_unpacked_dir().plus_file(MOD_DIR_NAME)
	var extension_path = mod_dir_path.plus_file("extensions/singletons/item_service.gd")
	ModLoaderMod.install_script_extension(extension_path)
	var data = ModLoaderStore.mod_data.get(MOD_ID)
	if data != null:
		_version = data.manifest.version_number


func _ready() -> void:
	call_deferred("_register_mod_options")


# Registers this mod's settings with dami-ModOptions (if installed), so they
# can be edited in-game from the Mod Options menu. Safe to run without it:
# the config then just stays at the bundled config.json defaults.
func _register_mod_options() -> void:
	var interface = get_node_or_null("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	if interface != null and not interface.is_connected("setting_changed", self, "_on_setting_changed"):
		interface.connect("setting_changed", self, "_on_setting_changed")

	var config = ModLoaderConfig.get_configs(MOD_ID).get(_version)
	if config == null:
		var default_config = ModLoaderConfig.get_default_config(MOD_ID)
		if default_config != null:
			config = ModLoaderConfig.create_config(MOD_ID, _version, default_config.data)
		else:
			config = ModLoaderConfig.create_config(MOD_ID, _version, {})
	if config == null:
		return
	for key in DEFAULT_SETTINGS:
		if not config.data.has(key):
			config.data[key] = DEFAULT_SETTINGS[key]
		if interface != null:
			interface.on_setting_changed(key, config.data[key], MOD_ID)
	config.save_path = "user://configs/" + MOD_ID + "/" + _version + ".json"
	config.save_to_file()
	ModLoaderLog.info("Registered settings with dami-ModOptions (config: %s)." % config.save_path, MOD_ID)


func _on_setting_changed(setting_name, value, mod_name) -> void:
	if mod_name != MOD_ID:
		return
	var config = ModLoaderConfig.get_current_config(MOD_ID)
	if config == null:
		return
	config.save_path = "user://configs/" + MOD_ID + "/" + _version + ".json"
	config.data[setting_name] = value
	config.save_to_file()
