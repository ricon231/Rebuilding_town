extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main := (
		load("res://main.tscn") as PackedScene
	).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	var player := main.get_node("Player") as CharacterBody2D
	var mine := main.get_node("Buildings/Mine")
	var gwana := main.get_node("Buildings/Gwana")
	var day_night := main.get_node("DayNightCycle")
	var artifact_catalog := root.get_node("ArtifactCatalog")

	main.set("current_day", 7)
	player.set("coins", 123)
	player.set("health", 61)
	player.global_position = Vector2(321.0, 654.0)
	mine.call("apply_saved_stage", 2)
	gwana.call("apply_saved_stage", 3)
	day_night.set("time_elapsed", 42.5)
	artifact_catalog.call("apply_registered_ids", [
		"phoenix_pillow",
		"guardian_tile",
	])
	assert(bool(player.call("try_add_artifact", &"deer_lunch_box")))
	assert(bool(player.call("try_add_artifact", &"zodiac_sundial")))

	assert(bool(main.call("save_game")))

	main.set("current_day", 0)
	player.set("coins", 0)
	player.set("health", 1)
	player.global_position = Vector2.ZERO
	mine.call("apply_saved_stage", 0)
	gwana.call("apply_saved_stage", 0)
	day_night.set("time_elapsed", 0.0)
	artifact_catalog.call("apply_registered_ids", [])
	player.call("remove_artifact_from_slot", 0)
	player.call("remove_artifact_from_slot", 1)

	assert(bool(main.call("load_game")))
	assert(int(main.get("current_day")) == 7)
	assert(int(player.get("coins")) == 123)
	assert(int(player.get("health")) == 61)
	assert(player.global_position.is_equal_approx(Vector2(321.0, 654.0)))
	assert(int(mine.get("current_stage")) == 2)
	assert(int(gwana.get("current_stage")) == 3)
	assert(is_equal_approx(float(day_night.get("time_elapsed")), 42.5))
	assert(bool(artifact_catalog.call("is_registered", &"phoenix_pillow")))
	assert(bool(artifact_catalog.call("is_registered", &"guardian_tile")))
	assert(
		player.call("get_artifact_in_slot", 0)
		== &"deer_lunch_box"
	)
	assert(
		player.call("get_artifact_in_slot", 1)
		== &"zodiac_sundial"
	)

	print("Save/load test passed.")
	quit()
