extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main_scene := load("res://main.tscn") as PackedScene
	var game := main_scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var mine: Node = game.get_node("Buildings/Mine")
	var blacksmith: Node = game.get_node("Buildings/Blacksmith")
	var gwana: Node = game.get_node("Buildings/Gwana")
	var player: Node = game.get_node("Player")

	mine.set("current_stage", 2)
	blacksmith.set("current_stage", 2)
	gwana.set("current_stage", 2)
	game.call("_on_building_upgraded", 2, blacksmith)
	game.call("_on_building_upgraded", 2, gwana)
	await process_frame

	var citizen_count := get_nodes_in_group("citizen").size()
	assert(citizen_count == 4, "관아 2단계의 주민은 4명이어야 합니다.")
	assert(int(player.get("attack_power")) == 34, "대장간 공격력 보너스가 맞지 않습니다.")

	var coins_before := int(player.get("coins"))
	var daily_income := int(game.call("_collect_daily_income"))
	assert(daily_income == 8, "광산과 주민의 일일 수입 합계가 맞지 않습니다.")
	assert(
		int(player.get("coins")) == coins_before + daily_income,
		"일일 수입이 플레이어 엽전에 반영되지 않았습니다."
	)

	gwana.set("current_stage", 4)
	game.call("_on_building_upgraded", 4, gwana)
	await process_frame
	assert(get_nodes_in_group("citizen").size() == 8, "주민 최대치는 8명이어야 합니다.")

	var citizens := get_nodes_in_group("citizen")
	citizens[0].call("take_damage", 999)
	citizens[1].call("take_damage", 999)
	assert(get_nodes_in_group("citizen").size() == 6)
	game.call("_welcome_daily_citizen")
	assert(get_nodes_in_group("citizen").size() == 7, "하루에 주민 1명만 보충되어야 합니다.")
	game.call("_welcome_daily_citizen")
	assert(get_nodes_in_group("citizen").size() == 8)
	game.call("_welcome_daily_citizen")
	assert(get_nodes_in_group("citizen").size() == 8, "주민 최대치를 초과했습니다.")

	print(
		"Town management test passed: citizens=%d, income=%d, attack=%d"
		% [citizen_count, daily_income, int(player.get("attack_power"))]
	)
	quit()
