extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var player := (
		load("res://player.tscn") as PackedScene
	).instantiate() as CharacterBody2D
	root.add_child(player)
	await process_frame

	player.set("attacking", true)
	player.call("_begin_thrust_dash")
	assert(bool(player.get("thrust_dashing")))
	assert(not bool(player.get("thrust_preparing")))
	assert(is_equal_approx(float(player.get("thrust_dash_distance")), 128.0))
	assert(is_equal_approx(float(player.get("thrust_dash_speed")), 1280.0))
	assert(
		(player.get_node("AnimatedSprite2D") as AnimatedSprite2D).animation
		== &"thrust_attack"
	)

	var trail_count := 0
	var trail: AnimatedSprite2D
	for child in root.get_children():
		if child is AnimatedSprite2D:
			trail_count += 1
			trail = child
	assert(trail_count == 1, "찌르기 시작 위치에 궤적 이펙트가 생성되어야 합니다.")
	assert(trail.frame == 1, "찌르기 이펙트는 두 번째 프레임만 사용해야 합니다.")
	assert(not trail.is_playing(), "찌르기 궤적은 애니메이션으로 재생되면 안 됩니다.")

	await create_timer(0.1).timeout
	assert(
		is_instance_valid(trail) and trail.modulate.a < 1.0,
		"찌르기 궤적은 0.2초 동안 점점 투명해져야 합니다."
	)
	await create_timer(0.12).timeout
	assert(
		not is_instance_valid(trail),
		"찌르기 궤적은 0.2초 안에 사라져야 합니다."
	)

	player.call("_begin_thrust_recover")
	assert(bool(player.get("thrust_recovering")))
	assert(not bool(player.get("thrust_dashing")))
	assert(
		(player.get_node("AnimatedSprite2D") as AnimatedSprite2D).animation
		== &"thrust_prepare"
	)

	player.call("_finish_thrust")
	assert(not bool(player.get("thrust_recovering")))
	assert(
		(player.get_node("AnimatedSprite2D") as AnimatedSprite2D).animation
		== &"idle"
	)

	print("Thrust motion test passed.")
	quit()
