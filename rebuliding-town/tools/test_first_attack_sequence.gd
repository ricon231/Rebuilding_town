extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var player := (
		load("res://player.tscn") as PackedScene
	).instantiate() as CharacterBody2D
	root.add_child(player)
	await process_frame

	player.call("_start_attack")
	var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var trail := player.get_node("SwordTrail") as AnimatedSprite2D
	var hitbox := player.get_node("SwordHitbox") as Area2D

	assert(bool(player.get("attack_preparing")))
	assert(sprite.animation == &"attack_prepare")
	assert(not trail.visible)
	assert(not hitbox.monitoring)
	assert(trail.scale.is_equal_approx(Vector2(0.64, 0.64)))
	assert(is_equal_approx(trail.position.y, -23.34))

	assert(
		is_equal_approx(float(player.get("attack_prepare_time_remaining")), 0.2),
		"첫 공격 준비 시간은 0.2초로 시작해야 합니다."
	)

	player.call("_process_attack_prepare", 0.19)
	assert(
		bool(player.get("attack_preparing")),
		"0.2초가 지나기 전에는 첫 공격 준비 자세를 유지해야 합니다."
	)
	assert(sprite.animation == &"attack_prepare")
	assert(not trail.visible)
	assert(not hitbox.monitoring)

	player.call("_process_attack_prepare", 0.011)
	await process_frame

	assert(
		not bool(player.get("attack_preparing")),
		"0.2초 뒤 첫 공격 준비 상태가 끝나야 합니다."
	)
	assert(sprite.animation == &"attack")
	assert(trail.visible)
	assert(trail.frame == 2, "베어내기 이펙트는 세 번째 프레임만 사용해야 합니다.")
	assert(not trail.is_playing(), "베어내기 이펙트는 애니메이션으로 재생되면 안 됩니다.")
	assert(hitbox.monitoring)

	for frame_index in 4:
		await process_frame
	assert(
		trail.visible and trail.modulate.a < 1.0,
		"베어내기 이펙트는 0.2초 동안 점점 투명해져야 합니다."
	)
	for frame_index in 12:
		await process_frame
	assert(not trail.visible, "베어내기 이펙트는 0.2초 안에 사라져야 합니다.")
	assert(not hitbox.monitoring)
	assert(not bool(player.get("attacking")))

	print("First attack sequence test passed.")
	quit()
