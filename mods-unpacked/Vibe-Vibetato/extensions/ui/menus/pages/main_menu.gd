extends "res://ui/menus/pages/main_menu.gd"

const Core = preload("res://mods-unpacked/Vibe-Vibetato/src/vibetato_core.gd")


func init() -> void:
	.init()
	Core.apply_preset_to_debug_service()
	Core.apply_boss_waves_from_preset()
