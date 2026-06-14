extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := (
		load("res://main.tscn") as PackedScene
	).instantiate()
	root.add_child(game)
	await process_frame

	var button := game.get_node("PlayerHUD/DayThreeButton") as Button
	var day_label := game.get_node("PlayerHUD/DayLabel") as Label

	assert(button.visible)
	assert(not button.disabled)
	button.pressed.emit()
	await process_frame

	assert(int(game.get("current_day")) == 3)
	assert(day_label.text == "3 일차")
	assert(
		get_nodes_in_group("raid_mob").size() == 3,
		"3일차 버튼을 누르면 적대 몹 3마리의 습격이 발생해야 합니다."
	)

	print("Day three button test passed.")
	quit()
