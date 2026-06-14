extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := (
		load("res://main.tscn") as PackedScene
	).instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame

	var artifact_pickups := game.get_node("Pickups/ArtifactPickups")
	var passive_animals := game.get_node("Animals/Passive")
	var chicken_scene := load("res://chicken.tscn") as PackedScene

	var first_chicken := chicken_scene.instantiate() as CharacterBody2D
	first_chicken.set("artifact_drop_chance", 0.0)
	passive_animals.add_child(first_chicken)
	first_chicken.call("take_damage", int(first_chicken.get("max_health")))
	await process_frame
	await process_frame

	assert(
		artifact_pickups.get_child_count() == 1,
		"첫 번째로 죽은 몹이 유물을 확정적으로 떨어뜨리지 않았습니다."
	)

	var second_chicken := chicken_scene.instantiate() as CharacterBody2D
	second_chicken.set("artifact_drop_chance", 0.0)
	passive_animals.add_child(second_chicken)
	second_chicken.call("take_damage", int(second_chicken.get("max_health")))
	await process_frame
	await process_frame

	assert(
		artifact_pickups.get_child_count() == 1,
		"두 번째 몹에도 첫 처치 확정 드롭이 중복 적용되었습니다."
	)

	print("First mob artifact drop test passed.")
	quit()
