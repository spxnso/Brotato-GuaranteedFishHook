extends "res://singletons/progress_data.gd"

const Core = preload("res://mods-unpacked/Vibe-Vibetato/src/vibetato_core.gd")


func check_for_available_dlcs() -> void:
	.check_for_available_dlcs()
	Core.apply_boss_waves_from_preset()
