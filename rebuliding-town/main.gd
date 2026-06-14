extends Node

const CITIZEN_SCENE := preload("res://citizen.tscn")
const MINE_COINS_PER_STAGE := 2
const CITIZEN_TAX_PER_DAY := 1
const BLACKSMITH_ATTACK_BONUS_PER_STAGE := 0.15
const CITIZENS_PER_GWANA_STAGE := 2
const MAX_CITIZENS := 8
const VICTORY_GWANA_STAGE := 4
const REBUILD_DEADLINE_DAY := 30
const SAVE_PATH := "user://rebuilding_town_save.json"
const SAVE_VERSION := 1

@export_range(0, 999999, 1) var current_day := 0
@export_range(0.1, 60.0, 0.1) var daytime_heal_interval := 2.0

@onready var day_night_cycle: Node = $DayNightCycle
@onready var player_hud: CanvasLayer = $PlayerHUD
@onready var pause_ui: CanvasLayer = $PauseUI
@onready var player: CharacterBody2D = $Player
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var mob_spawner: Node2D = $MobSpawner
@onready var mine: Node = $Buildings/Mine
@onready var blacksmith: Node = $Buildings/Blacksmith
@onready var gwana: Node = $Buildings/Gwana
@onready var restoration_lab: Node = $Buildings/RestorationLab
@onready var citizens: Node2D = $Citizens
@onready var citizen_spawn_points: Node = $CitizenSpawnPoints

var daytime_heal_elapsed := 0.0
var game_over := false
var deadline_failed := false
var citizen_spawn_cursor := 0
var first_mob_death_processed := false


func _ready() -> void:
	day_night_cycle.connect(&"day_completed", _on_day_completed)
	player.connect(&"died", _on_player_died)
	ArtifactCatalog.artifact_registered.connect(_on_artifact_registered)
	player_hud.connect(&"day_three_requested", _on_day_three_requested)
	_connect_building(mine)
	_connect_building(blacksmith)
	_connect_building(gwana)
	_connect_building(restoration_lab)
	_apply_town_bonuses()
	_fill_citizen_capacity()
	_refresh_town_status()
	_check_victory_condition()


func _on_day_three_requested() -> void:
	if game_over:
		return
	current_day = 3
	if player_hud.has_method("show_current_day"):
		player_hud.call("show_current_day", current_day)
	var raid_count := int(mob_spawner.call("spawn_raid", current_day))
	_refresh_town_status()
	if raid_count > 0:
		_show_message(
			"3일차로 변경했습니다. 적대 몹 %d마리가 몰려옵니다!" % raid_count
		)
	else:
		_show_message("현재 날짜를 3일차로 변경했습니다.")


func _process(delta: float) -> void:
	if game_over:
		return
	var can_recover: bool = (
		bool(day_night_cycle.call("is_daytime"))
		or player.can_recover_at_night()
	)
	if not can_recover:
		daytime_heal_elapsed = 0.0
		return

	daytime_heal_elapsed += delta
	while daytime_heal_elapsed >= daytime_heal_interval:
		daytime_heal_elapsed -= daytime_heal_interval
		if player.health < player.max_health:
			player.heal(player.get_periodic_heal_amount())


func claim_first_mob_artifact_drop() -> bool:
	if first_mob_death_processed:
		return false
	first_mob_death_processed = true
	return true


func _on_day_completed() -> void:
	current_day += 1
	if player_hud.has_method("show_current_day"):
		player_hud.call("show_current_day", current_day)
	if current_day >= REBUILD_DEADLINE_DAY and not _is_rebuild_complete():
		_start_deadline_failure()
		return

	player.reset_daily_artifact_effects()
	_welcome_daily_citizen()
	var daily_income := _collect_daily_income()
	if daily_income > 0:
		_show_message("마을 수입으로 엽전 %d개를 획득했습니다." % daily_income)
	if current_day > 0 and current_day <= 30 and current_day % 3 == 0:
		var raid_count := int(mob_spawner.call("spawn_raid", current_day))
		if raid_count > 0:
			_show_message(
				"오른쪽에서 적대 몹 %d마리가 마을로 몰려옵니다!" % raid_count
			)
	_refresh_town_status()


func _connect_building(building: Node) -> void:
	if building != null and building.has_signal("upgraded"):
		building.connect(&"upgraded", _on_building_upgraded.bind(building))


func _on_building_upgraded(_new_stage: int, building: Node) -> void:
	_apply_town_bonuses()
	if building == gwana:
		_fill_citizen_capacity()
	_show_message(_get_upgrade_message(building))
	_refresh_town_status()
	_check_victory_condition()


func _on_artifact_registered(_artifact_id: StringName) -> void:
	_refresh_town_status()
	_check_victory_condition()


func _check_victory_condition() -> void:
	if game_over or deadline_failed:
		return
	if not _is_rebuild_complete():
		return

	game_over = true
	game_over_ui.call("show_results", _calculate_score(), true)


func _is_rebuild_complete() -> bool:
	return (
		ArtifactCatalog.registered.size()
		>= ArtifactCatalog.ARTIFACTS.size()
		and _get_building_stage(gwana) >= VICTORY_GWANA_STAGE
	)


func _start_deadline_failure() -> void:
	if deadline_failed or game_over:
		return

	deadline_failed = true
	day_night_cycle.call("lock_to_night")
	mob_spawner.call("start_rebuild_failure")
	_show_message(
		"30일 안에 마을을 재건하지 못했습니다. "
		+ "밤이 멈추고 2초마다 적이 몰려옵니다!"
	)
	_refresh_town_status()


func _apply_town_bonuses() -> void:
	var blacksmith_stage := _get_building_stage(blacksmith)
	player.set_town_attack_bonus(
		float(blacksmith_stage) * BLACKSMITH_ATTACK_BONUS_PER_STAGE
	)


func _collect_daily_income() -> int:
	var mine_income := _get_building_stage(mine) * MINE_COINS_PER_STAGE
	var citizen_income := (
		get_tree().get_nodes_in_group("citizen").size()
		* CITIZEN_TAX_PER_DAY
	)
	var total_income := mine_income + citizen_income
	if total_income > 0:
		player.add_coins(total_income)
	return total_income


func _get_citizen_capacity() -> int:
	return mini(
		_get_building_stage(gwana) * CITIZENS_PER_GWANA_STAGE,
		MAX_CITIZENS
	)


func _fill_citizen_capacity() -> void:
	var missing := (
		_get_citizen_capacity()
		- get_tree().get_nodes_in_group("citizen").size()
	)
	for _index in maxi(missing, 0):
		_spawn_citizen()


func _welcome_daily_citizen() -> void:
	var current_count := get_tree().get_nodes_in_group("citizen").size()
	if current_count < _get_citizen_capacity():
		_spawn_citizen_at_gwana()
		_show_message("관아에서 새로운 주민 1명이 합류했습니다.")


func _spawn_citizen() -> void:
	var spawn_points := citizen_spawn_points.get_children()
	if spawn_points.is_empty():
		return

	var citizen := CITIZEN_SCENE.instantiate() as CharacterBody2D
	if citizen == null:
		return
	var spawn_point := spawn_points[
		citizen_spawn_cursor % spawn_points.size()
	] as Marker2D
	citizen_spawn_cursor += 1
	citizens.add_child(citizen)
	citizen.global_position = spawn_point.global_position
	citizen.died.connect(_on_citizen_died)


func _spawn_citizen_at_gwana() -> void:
	var current_count := get_tree().get_nodes_in_group("citizen").size()
	if current_count >= _get_citizen_capacity() or current_count >= MAX_CITIZENS:
		return

	var citizen := CITIZEN_SCENE.instantiate() as CharacterBody2D
	if citizen == null:
		return
	citizens.add_child(citizen)
	var side := -1.0 if current_count % 2 == 0 else 1.0
	var row := float(current_count / 2)
	citizen.global_position = gwana.global_position + Vector2(
		side * (54.0 + row * 18.0),
		18.0
	)
	citizen.died.connect(_on_citizen_died)


func _on_citizen_died() -> void:
	_refresh_town_status.call_deferred()
	_show_message("주민이 희생되었습니다. 마을을 방어하세요.")


func _refresh_town_status() -> void:
	if not player_hud.has_method("show_town_status"):
		return
	var citizen_count := get_tree().get_nodes_in_group("citizen").size()
	var mine_stage := _get_building_stage(mine)
	var blacksmith_stage := _get_building_stage(blacksmith)
	var gwana_stage := _get_building_stage(gwana)
	var restoration_stage := _get_building_stage(restoration_lab)
	var status_text: String = player_hud.call(
		"show_town_status",
		{
			"citizens": citizen_count,
			"capacity": _get_citizen_capacity(),
			"mine_stage": mine_stage,
			"mine_income": mine_stage * MINE_COINS_PER_STAGE,
			"blacksmith_stage": blacksmith_stage,
			"attack_bonus": roundi(
				blacksmith_stage
				* BLACKSMITH_ATTACK_BONUS_PER_STAGE
				* 100.0
			),
			"gwana_stage": gwana_stage,
			"victory_gwana_stage": VICTORY_GWANA_STAGE,
			"restoration_stage": restoration_stage,
			"artifact_count": ArtifactCatalog.registered.size(),
			"artifact_total": ArtifactCatalog.ARTIFACTS.size(),
			"daily_income": (
				mine_stage * MINE_COINS_PER_STAGE
				+ citizen_count * CITIZEN_TAX_PER_DAY
			),
		}
	)
	if pause_ui.has_method("show_town_status"):
		pause_ui.call("show_town_status", status_text)


func _get_upgrade_message(building: Node) -> String:
	var stage := _get_building_stage(building)
	if building == mine:
		return "광산 %d단계: 하루 광산 수입이 %d엽전이 되었습니다." % [
			stage,
			stage * MINE_COINS_PER_STAGE,
		]
	if building == blacksmith:
		return "대장간 %d단계: 공격력이 총 %d%% 강화됩니다." % [
			stage,
			roundi(stage * BLACKSMITH_ATTACK_BONUS_PER_STAGE * 100.0),
		]
	if building == gwana:
		return "관아 %d단계: 주민 수용 인원이 %d명이 되었습니다." % [
			stage,
			_get_citizen_capacity(),
		]
	if building == restoration_lab:
		return "복원소 %d단계: 유물 복원 비용과 시간이 감소합니다." % stage
	return "건물이 %d단계로 복구되었습니다." % stage


func _get_building_stage(building: Node) -> int:
	if building == null:
		return 0
	return maxi(int(building.get("current_stage")), 0)


func _show_message(message: String) -> void:
	if player_hud.has_method("show_message"):
		player_hud.call("show_message", message)


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var save_data := {
		"version": SAVE_VERSION,
		"current_day": current_day,
		"day_night": day_night_cycle.call("get_save_data"),
		"player": player.call("get_save_data"),
		"buildings": {
			"mine": _get_building_stage(mine),
			"blacksmith": _get_building_stage(blacksmith),
			"gwana": _get_building_stage(gwana),
			"restoration_lab": _get_building_stage(restoration_lab),
		},
		"citizens": _get_citizen_save_data(),
		"registered_artifacts": ArtifactCatalog.get_registered_ids(),
		"citizen_spawn_cursor": citizen_spawn_cursor,
		"deadline_failed": deadline_failed,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(save_data, "\t"))
	return true


func load_game() -> bool:
	if not has_save_file():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var save_data: Dictionary = parsed
	if int(save_data.get("version", 0)) != SAVE_VERSION:
		return false

	game_over = false
	deadline_failed = bool(save_data.get("deadline_failed", false))
	current_day = maxi(int(save_data.get("current_day", 0)), 0)
	ArtifactCatalog.apply_registered_ids(
		save_data.get("registered_artifacts", [])
	)
	_apply_building_save_data(save_data.get("buildings", {}))
	day_night_cycle.call(
		"apply_save_data",
		save_data.get("day_night", {})
	)
	citizen_spawn_cursor = maxi(
		int(save_data.get("citizen_spawn_cursor", 0)),
		0
	)
	_restore_citizens(save_data.get("citizens", []))
	_apply_town_bonuses()
	player.call("apply_save_data", save_data.get("player", {}))
	_apply_town_bonuses()
	if deadline_failed:
		day_night_cycle.call("lock_to_night")
		mob_spawner.call("start_rebuild_failure")

	if player_hud.has_method("show_current_day"):
		player_hud.call("show_current_day", current_day)
	_refresh_town_status()
	_show_message("저장된 게임을 불러왔습니다.")
	_check_victory_condition()
	return true


func _apply_building_save_data(data: Dictionary) -> void:
	var buildings := {
		"mine": mine,
		"blacksmith": blacksmith,
		"gwana": gwana,
		"restoration_lab": restoration_lab,
	}
	for key in buildings:
		var building: Node = buildings[key]
		if building != null and building.has_method("apply_saved_stage"):
			building.call("apply_saved_stage", int(data.get(key, 0)))


func _get_citizen_save_data() -> Array[Dictionary]:
	var saved_citizens: Array[Dictionary] = []
	for child in citizens.get_children():
		var citizen := child as CharacterBody2D
		if citizen == null or not citizen.is_in_group("citizen"):
			continue
		saved_citizens.append({
			"position": [citizen.global_position.x, citizen.global_position.y],
			"health": int(citizen.get("health")),
			"clothing_variant": int(citizen.get("clothing_variant")),
		})
	return saved_citizens


func _restore_citizens(saved_citizens: Array) -> void:
	for child in citizens.get_children():
		child.free()
	for value in saved_citizens:
		if not value is Dictionary:
			continue
		var data: Dictionary = value
		var citizen := CITIZEN_SCENE.instantiate() as CharacterBody2D
		if citizen == null:
			continue
		citizen.set(
			"clothing_variant",
			clampi(int(data.get("clothing_variant", 0)), 0, 4)
		)
		citizens.add_child(citizen)
		var saved_position: Array = data.get("position", [])
		if saved_position.size() >= 2:
			citizen.global_position = Vector2(
				float(saved_position[0]),
				float(saved_position[1])
			)
		citizen.set(
			"health",
			clampi(
				int(data.get("health", citizen.get("max_health"))),
				1,
				int(citizen.get("max_health"))
			)
		)
		citizen.died.connect(_on_citizen_died)


func _on_player_died() -> void:
	if game_over:
		return
	game_over = true
	game_over_ui.call("show_results", _calculate_score())


func _calculate_score() -> Dictionary:
	var building_count := 0
	for building in get_tree().get_nodes_in_group("upgrade_building"):
		building_count += maxi(int(building.get("current_stage")), 0)

	var citizen_count := get_tree().get_nodes_in_group("citizen").size()
	var coin_count := maxi(int(player.get("coins")), 0)
	var artifact_count := ArtifactCatalog.registered.size()
	var day_count := maxi(current_day, 0)

	var building_score := building_count * 100
	var citizen_score := citizen_count * 8
	var coin_score := coin_count
	var artifact_score := artifact_count * 5
	var day_score := day_count * 10

	return {
		"building_count": building_count,
		"building_score": building_score,
		"citizen_count": citizen_count,
		"citizen_score": citizen_score,
		"coin_count": coin_count,
		"coin_score": coin_score,
		"artifact_count": artifact_count,
		"artifact_score": artifact_score,
		"day_count": day_count,
		"day_score": day_score,
		"total_score": (
			building_score
			+ citizen_score
			+ coin_score
			+ artifact_score
			+ day_score
		),
	}
