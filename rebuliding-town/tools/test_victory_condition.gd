extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := (
		load("res://main.tscn") as PackedScene
	).instantiate()
	root.add_child(game)
	await process_frame

	var result_ui := game.get_node("GameOverUI") as CanvasLayer
	var title := result_ui.get_node("Window/Margin/Column/Title") as Label
	var catalog = root.get_node("ArtifactCatalog")
	var gwana := game.get_node("Buildings/Gwana")

	gwana.call("apply_saved_stage", 4)
	for artifact in catalog.ARTIFACTS:
		catalog.call("register_artifact", artifact.id)
	await process_frame

	assert(
		int(gwana.get("current_stage")) == 4,
		"관아가 승리 조건 단계에 도달하지 못했습니다."
	)
	assert(
		catalog.registered.size() == catalog.ARTIFACTS.size(),
		"모든 유물이 복원되지 않았습니다."
	)
	assert(result_ui.visible, "승리 결과 화면이 표시되지 않았습니다.")
	assert(title.text == "마을 재건 완료", "승리 제목이 표시되지 않았습니다.")
	assert(bool(game.get("game_over")), "게임이 승리 종료 상태가 아닙니다.")

	print("Victory condition test passed.")
	paused = false
	quit()
