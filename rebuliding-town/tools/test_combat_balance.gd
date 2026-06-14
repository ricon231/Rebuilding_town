extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var player := (
		load("res://player.tscn") as PackedScene
	).instantiate() as CharacterBody2D
	root.add_child(player)
	await process_frame

	assert(int(player.get("attack_power")) == 26)

	var starting_health := int(player.get("health"))
	player.call("take_damage", 12)
	player.call("take_damage", 12)
	assert(
		int(player.get("health")) == starting_health - 12,
		"피격 보호 시간 동안 중복 피해를 받았습니다."
	)

	var expected_stats := {
		"res://boar.tscn": [90, 12, 4],
		"res://bear.tscn": [160, 20, 7],
		"res://tiger.tscn": [200, 26, 10],
	}
	for scene_path in expected_stats:
		var mob := (
			load(scene_path) as PackedScene
		).instantiate() as CharacterBody2D
		var expected: Array = expected_stats[scene_path]
		assert(int(mob.get("max_health")) == expected[0])
		assert(int(mob.get("attack_power")) == expected[1])
		assert(int(mob.get("coin_drop_count")) == expected[2])
		mob.free()

	print("Combat balance test passed.")
	quit()
