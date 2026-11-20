extends "res://main.gd"

const Core = preload("res://mods-unpacked/Vibe-Vibetato/src/vibetato_core.gd")
const LOG_NAME := "Vibe-Vibetato:Main"


func _on_EntitySpawner_players_spawned(players: Array) -> void:
	._on_EntitySpawner_players_spawned(players)
	if not Core.is_enabled():
		return
	var preset: Dictionary = Core.get_preset()
	if preset.has("seed"):
		var s := int(preset["seed"])
		seed(s)
		ModLoaderLog.info("Run seed set to %d." % s, LOG_NAME)
	if preset.has("speed_multiplier"):
		var spd := clamp(float(preset["speed_multiplier"]), 0.25, 8.0)
		Engine.time_scale = spd
		ModLoaderLog.info("Speed multiplier x%s applied at run start." % str(spd), LOG_NAME)


func clean_up_room(is_last_wave: bool = false, is_run_lost: bool = false, is_run_won: bool = false) -> void:
	.clean_up_room(is_last_wave, is_run_lost, is_run_won)
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
		ModLoaderLog.info("Speed multiplier reset to x1.", LOG_NAME)
