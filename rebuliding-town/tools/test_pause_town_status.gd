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

	var player_hud := main.get_node("PlayerHUD")
	var pause_ui := main.get_node("PauseUI")
	var hud_panel := player_hud.get_node("TownStatusPanel") as Control
	var pause_panel := pause_ui.get_node("TownStatusPanel") as Control
	var pause_label := pause_ui.get_node(
		"TownStatusPanel/TownStatusLabel"
	) as Label

	assert(not hud_panel.visible, "일반 플레이 중 마을 설명 UI는 숨겨져야 합니다.")
	assert(not pause_ui.visible)

	pause_ui.call("_pause_game")
	assert(pause_ui.visible)
	assert(pause_panel.visible)
	assert(pause_label.text.contains("마을 운영"))
	assert(pause_label.text.contains("승리 목표"))

	pause_ui.call("_resume_game")
	assert(not pause_ui.visible)
	assert(not hud_panel.visible)

	print("Pause town status test passed.")
	quit()
