extends Area2D

@export_category("Coin")
@export var coin_value: int = 1

@export_category("Launch")
@export var auto_launch_on_spawn := true
@export var launch_spawn_height := 32.0
@export var launch_horizontal_speed := 95.0
@export var launch_vertical_speed := 230.0
@export var launch_variation := 35.0
@export var launch_gravity: float = 620.0
@export var maximum_fall_speed: float = 520.0
@export var launch_spin_speed_range := Vector2(4.0, 8.0)
@export_flags_2d_physics var ground_collision_mask := 1
@export var ground_clearance := 6.0

@export_category("Magnet")
@export var magnet_distance: float = 120.0
@export var magnet_speed: float = 260.0
@export var magnet_acceleration: float = 900.0
@export var pickup_distance: float = 10.0
@export var magnet_delay: float = 3.0

var player: Node2D
var current_speed := 0.0
var magnet_delay_remaining := 0.0
var collected := false
var launch_velocity := Vector2.ZERO
var launch_spin_speed := 0.0
var launching := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	magnet_delay_remaining = maxf(magnet_delay, 0.0)
	if auto_launch_on_spawn:
		_start_spawn_launch.call_deferred()


func _physics_process(delta: float) -> void:
	if collected:
		return

	magnet_delay_remaining = maxf(magnet_delay_remaining - delta, 0.0)
	if launching:
		_update_launch(delta)
		return

	if magnet_delay_remaining > 0.0:
		current_speed = 0.0
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		return

	var distance := global_position.distance_to(player.global_position)
	if distance > magnet_distance:
		current_speed = 0.0
		return

	current_speed = move_toward(
		current_speed,
		magnet_speed,
		magnet_acceleration * delta
	)
	global_position = global_position.move_toward(
		player.global_position,
		current_speed * delta
	)

	if distance <= pickup_distance:
		_collect(player)


func _start_spawn_launch() -> void:
	if not is_inside_tree() or collected:
		return

	global_position.y -= launch_spawn_height
	launch_velocity = Vector2(
		randf_range(-launch_horizontal_speed, launch_horizontal_speed),
		-launch_vertical_speed + randf_range(-launch_variation, launch_variation)
	)
	launch_spin_speed = randf_range(
		launch_spin_speed_range.x,
		launch_spin_speed_range.y
	) * (-1.0 if randf() < 0.5 else 1.0)
	launching = true


func _update_launch(delta: float) -> void:
	launch_velocity.y = minf(
		launch_velocity.y + launch_gravity * delta,
		maximum_fall_speed
	)
	var next_position := global_position + launch_velocity * delta

	if launch_velocity.y >= 0.0:
		var ground_hit := _find_ground_between(global_position, next_position)
		if not ground_hit.is_empty():
			var hit_position: Vector2 = ground_hit.get("position", next_position)
			global_position = Vector2(
				next_position.x,
				hit_position.y - ground_clearance
			)
			_finish_launch()
			return

	global_position = next_position
	rotation += launch_spin_speed * delta


func _find_ground_between(from_position: Vector2, to_position: Vector2) -> Dictionary:
	var ray_start := Vector2(to_position.x, from_position.y + ground_clearance)
	var ray_end := Vector2(to_position.x, to_position.y + ground_clearance)
	if ray_end.y <= ray_start.y:
		return {}

	var query := PhysicsRayQueryParameters2D.create(
		ray_start,
		ray_end,
		ground_collision_mask
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query)


func _finish_launch() -> void:
	launch_velocity = Vector2.ZERO
	launch_spin_speed = 0.0
	rotation = 0.0
	launching = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)


func _collect(body: Node) -> void:
	if collected:
		return

	collected = true
	set_deferred("monitoring", false)

	if body.has_method("add_coins"):
		body.add_coins(coin_value)

	queue_free()
