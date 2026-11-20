extends Node

const MOD_ID = "Vibe-Vibetato"
const Core = preload("res://mods-unpacked/Vibe-Vibetato/src/vibetato_core.gd")
const PanelScene = preload("res://mods-unpacked/Vibe-Vibetato/src/vibetato_panel.gd")


func _init() -> void:
	ModLoaderLog.info("Initialized.", MOD_ID)
	var mod_dir_path = ModLoaderMod.get_unpacked_dir().plus_file(MOD_ID)
	ModLoaderMod.install_script_extension(mod_dir_path.plus_file("extensions/singletons/item_service.gd"))
	ModLoaderMod.install_script_extension(mod_dir_path.plus_file("extensions/singletons/progress_data.gd"))
	ModLoaderMod.install_script_extension(mod_dir_path.plus_file("extensions/singletons/run_data.gd"))
	ModLoaderMod.install_script_extension(mod_dir_path.plus_file("extensions/main.gd"))


func _ready() -> void:
	call_deferred("_apply_state")


func _apply_state() -> void:
	Core.reload_state()
	_build_panel()
	ModLoaderLog.info("Ready.", MOD_ID)


func _build_panel() -> void:
	var root = get_tree().root
	if root == null or root.has_node("VibeVibetatoPanel"):
		return
	var panel = PanelScene.new()
	root.add_child(panel)
	RunData.set("vibe_vibetato_panel", panel)


func _unhandled_input(event) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var cfg: Dictionary = Core.get_config()
	var key: String = String(cfg.get("hotkey_speed_cycle", "F9")).to_upper()
	if String(event.as_text()).to_upper() == key:
		Core.cycle_speed()
