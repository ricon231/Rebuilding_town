extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := (
		load("res://main.tscn") as PackedScene
	).instantiate()
	root.add_child(game)
	await process_frame

	game.call("_on_day_completed")
	game.call("_on_day_completed")
	assert(get_nodes_in_group("raid_mob").is_empty(), "3일 이전에 습격이 시작됐습니다.")
	game.call("_on_day_completed")
	await process_frame

	var raid_mobs := get_nodes_in_group("raid_mob")
	assert(raid_mobs.size() == 3, "3일차 습격은 적대 몹 3마리여야 합니다.")
	for mob in raid_mobs:
		assert(bool(mob.get("raid_mode")), "습격 몹의 마을 이동이 설정되지 않았습니다.")
		assert(
			float(mob.global_position.x) >= 4400.0,
			"습격 몹이 오른쪽에서 생성되지 않았습니다."
		)
		assert(float(mob.velocity.x) < 0.0, "습격 몹이 마을 방향으로 이동하지 않습니다.")
		assert(mob.collision_layer == 4 and mob.collision_mask == 1)

	var spawner := game.get_node("MobSpawner")
	assert(int(spawner.call("spawn_raid", 30)) == 15, "30일차 습격은 15마리여야 합니다.")
	assert(int(spawner.call("spawn_raid", 33)) == 0, "30일 이후에는 습격이 없어야 합니다.")

	print("Raid flow test passed.")
	quit()
