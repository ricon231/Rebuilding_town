extends Node2D

@export_category("Spawn Timing")
@export_range(0.1, 300.0, 0.1) var spawn_interval := 14.0
@export_range(0.0, 300.0, 0.1) var first_spawn_delay := 3.0
@export_range(1, 100, 1) var maximum_spawned_mobs := 8

@export_category("Date Probability")
@export_range(0.0, 1.0, 0.01) var first_day_friendly_chance := 0.7
@export_range(0.0, 1.0, 0.01) var friendly_chance_loss_per_day := 0.05
@export_range(0.0, 1.0, 0.01) var minimum_friendly_chance := 0.15
@export_range(1, 999999, 1) var tiger_first_day := 5

@export_category("Spawn Rules")
@export_range(0.0, 2000.0, 1.0) var minimum_player_distance := 180.0
@export_range(0.0, 1000.0, 1.0) var camera_outside_margin := 80.0
@export var main_node_path := NodePath("..")
@export var friendly_parent_path := NodePath("../Animals/Passive")
@export var hostile_parent_path := NodePath("../Animals/Hostile")

@export_category("Raid")
@export_range(1, 30, 1) var raid_base_count := 3
@export_range(0, 10, 1) var raid_growth_per_wave := 2
@export_range(1, 30, 1) var raid_max_count := 15
@export_range(3, 999999, 3) var raid_last_day := 30
@export var raid_spawn_position := Vector2(4600.0, 620.0)
@export var raid_target_position := Vector2(2500.0, 620.0)
@export_range(0.0, 200.0, 1.0) var raid_spawn_spacing := 64.0

@export_category("Rebuild Failure")
@export_range(0.1, 30.0, 0.1) var failure_spawn_interval := 2.0
@export_range(1, 100, 1) var failure_maximum_spawned_mobs := 30

@export_category("Mob Scenes")
@export var friendly_scenes: Array[PackedScene] = [
	preload("res://deer.tscn"),
	preload("res://chicken.tscn"),
]
@export var hostile_scenes: Array[PackedScene] = [
	preload("res://boar.tscn"),
	preload("res://bear.tscn"),
]
@export var tiger_scene: PackedScene = preload("res://tiger.tscn")

@onready var friendly_spawn_points: Node = $FriendlySpawnPoints
@onready var hostile_spawn_points: Node = $HostileSpawnPoints

var spawn_timer := 0.0
var failure_mode := false
var failure_spawn_cursor := 0


func _ready() -> void:
	spawn_timer = first_spawn_delay


func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	if failure_mode:
		spawn_timer = failure_spawn_interval
		_spawn_failure_mob()
	else:
		spawn_timer = spawn_interval
		_try_spawn_mob()


func start_rebuild_failure() -> void:
	failure_mode = true
	spawn_timer = failure_spawn_interval


func is_rebuild_failure_active() -> bool:
	return failure_mode


func get_friendly_chance(day: int) -> float:
	var elapsed_days := maxi(day - 1, 0)
	return clampf(
		first_day_friendly_chance - friendly_chance_loss_per_day * elapsed_days,
		minimum_friendly_chance,
		1.0
	)


func _try_spawn_mob() -> void:
	if get_tree().get_nodes_in_group("spawned_mob").size() >= maximum_spawned_mobs:
		return

	var day := _get_current_day()
	var spawn_friendly := randf() < get_friendly_chance(day)
	var scene := _choose_scene(spawn_friendly, day)
	var spawn_point := _choose_spawn_point(spawn_friendly)
	if scene == null or spawn_point == null:
		return

	var target_parent := get_node_or_null(
		friendly_parent_path if spawn_friendly else hostile_parent_path
	)
	if target_parent == null:
		return

	var mob := scene.instantiate() as Node2D
	if mob == null:
		return

	target_parent.add_child(mob)
	mob.global_position = spawn_point.global_position
	mob.add_to_group("spawned_mob")


func spawn_raid(day: int) -> int:
	if day <= 0 or day > raid_last_day or day % 3 != 0:
		return 0
	var target_parent := get_node_or_null(hostile_parent_path)
	if target_parent == null:
		return 0

	var wave_index := maxi(floori(float(day) / 3.0) - 1, 0)
	var raid_count := mini(
		raid_base_count + wave_index * raid_growth_per_wave,
		raid_max_count
	)
	var spawned_count := 0
	for mob_index in raid_count:
		var scene := _choose_scene(false, day)
		if scene == null:
			continue
		var mob := scene.instantiate() as Node2D
		if mob == null:
			continue

		target_parent.add_child(mob)
		mob.global_position = raid_spawn_position + Vector2(
			float(mob_index) * raid_spawn_spacing,
			0.0
		)
		mob.add_to_group("spawned_mob")
		mob.add_to_group("raid_mob")
		if mob.has_method("configure_raid"):
			mob.call("configure_raid", raid_target_position)
		spawned_count += 1
	return spawned_count


func _spawn_failure_mob() -> void:
	if (
		get_tree().get_nodes_in_group("spawned_mob").size()
		>= failure_maximum_spawned_mobs
	):
		return

	var target_parent := get_node_or_null(hostile_parent_path)
	if target_parent == null:
		return
	var scene := _choose_scene(false, maxi(_get_current_day(), tiger_first_day))
	if scene == null:
		return
	var mob := scene.instantiate() as Node2D
	if mob == null:
		return

	target_parent.add_child(mob)
	var lane_offset := float(failure_spawn_cursor % 5) * raid_spawn_spacing
	mob.global_position = raid_spawn_position + Vector2(lane_offset, 0.0)
	failure_spawn_cursor += 1
	mob.add_to_group("spawned_mob")
	mob.add_to_group("raid_mob")
	if mob.has_method("configure_raid"):
		mob.call("configure_raid", raid_target_position)


func _choose_scene(friendly: bool, day: int) -> PackedScene:
	var candidates: Array[PackedScene] = []
	if friendly:
		candidates.assign(friendly_scenes)
	else:
		candidates.assign(hostile_scenes)
		if day >= tiger_first_day and tiger_scene != null:
			candidates.append(tiger_scene)

	if candidates.is_empty():
		return null
	return candidates.pick_random()


func _choose_spawn_point(friendly: bool) -> Marker2D:
	var point_root := friendly_spawn_points if friendly else hostile_spawn_points
	var candidates: Array[Marker2D] = []
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var visible_world_rect := _get_camera_world_rect()

	for child in point_root.get_children():
		var marker := child as Marker2D
		if marker == null:
			continue
		if visible_world_rect.has_point(marker.global_position):
			continue
		if is_instance_valid(player):
			if marker.global_position.distance_to(player.global_position) < minimum_player_distance:
				continue
		candidates.append(marker)

	if candidates.is_empty():
		return null
	return candidates.pick_random()


func _get_camera_world_rect() -> Rect2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return Rect2()

	var viewport_size := get_viewport_rect().size
	var camera_zoom := camera.zoom.abs()
	var world_size := Vector2(
		viewport_size.x / maxf(camera_zoom.x, 0.001),
		viewport_size.y / maxf(camera_zoom.y, 0.001)
	)
	return Rect2(camera.get_screen_center_position() - world_size * 0.5, world_size).grow(
		camera_outside_margin
	)


func _get_current_day() -> int:
	var main_node := get_node_or_null(main_node_path)
	if main_node == null:
		return 1
	return maxi(int(main_node.get("current_day")), 0)
