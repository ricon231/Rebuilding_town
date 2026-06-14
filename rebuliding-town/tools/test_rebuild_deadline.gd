extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := (
		load("res://main.tscn") as PackedScene
	).instantiate()
	root.add_child(game)
	await process_frame

	game.set("current_day", 29)
	game.call("_on_day_completed")
	await process_frame

	var cycle := game.get_node("DayNightCycle")
	var spawner := game.get_node("MobSpawner")
	assert(int(game.get("current_day")) == 30)
	assert(bool(game.get("deadline_failed")))
	assert(bool(cycle.call("is_time_locked")))
	assert(not bool(cycle.call("is_daytime")))
	assert(bool(spawner.call("is_rebuild_failure_active")))
	assert(is_equal_approx(float(spawner.get("failure_spawn_interval")), 2.0))

	var before_count := get_nodes_in_group("spawned_mob").size()
	spawner.call("_process", 2.0)
	await process_frame
	assert(get_nodes_in_group("spawned_mob").size() == before_count + 1)

	print("Rebuild deadline test passed.")
	quit()
