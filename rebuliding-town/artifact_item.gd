extends CharacterBody2D

@export var artifact_id: StringName
@export var remove_if_already_registered := false

@export_category("Duplicate Reward")
@export var duplicate_coin_scene: PackedScene = preload("res://coin.tscn")
@export_range(0, 100, 1) var duplicate_coin_count := 5
@export var duplicate_coin_scatter := Vector2(28.0, 12.0)

@export_category("Physics")
@export var gravity := 980.0
@export var maximum_fall_speed := 900.0

@export_category("Magnet")
@export var magnet_distance := 120.0
@export var magnet_speed := 260.0
@export var magnet_acceleration := 900.0
@export var pickup_distance := 14.0
@export var magnet_delay := 3.0

@export_category("Display")
@export var float_height := 2.0
@export var float_speed := 2.2

@onready var sprite: Sprite2D = $Sprite2D
@onready var pickup_area: Area2D = $PickupArea

var player: Node2D
var sprite_start_y := 0.0
var elapsed := 0.0
var current_magnet_speed := 0.0
var magnet_delay_remaining := 0.0
var collected := false
var pickup_reject_time := 0.0


func _ready() -> void:
	sprite_start_y = sprite.position.y
	player = get_tree().get_first_node_in_group("player") as Node2D
	magnet_delay_remaining = maxf(magnet_delay, 0.0)
	if remove_if_already_registered and ArtifactCatalog.is_registered(artifact_id):
		queue_free()


func _physics_process(delta: float) -> void:
	if collected:
		return

	elapsed += delta
	pickup_reject_time = maxf(pickup_reject_time - delta, 0.0)
	if is_on_floor():
		sprite.position.y = sprite_start_y + sin(elapsed * float_speed) * float_height
		if velocity.y > 0.0:
			velocity.y = 0.0
	else:
		sprite.position.y = sprite_start_y
		velocity.y = minf(velocity.y + gravity * delta, maximum_fall_speed)

	magnet_delay_remaining = maxf(magnet_delay_remaining - delta, 0.0)
	if magnet_delay_remaining <= 0.0:
		_apply_magnet(delta)

	move_and_slide()


func _on_body_entered(body: Node2D) -> void:
	if collected or pickup_reject_time > 0.0 or not body.is_in_group("player"):
		return
	_collect(body)


func _apply_magnet(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		return

	var distance := global_position.distance_to(player.global_position)
	if distance > magnet_distance:
		current_magnet_speed = 0.0
		velocity.x = 0.0
		return

	current_magnet_speed = move_toward(
		current_magnet_speed,
		magnet_speed,
		magnet_acceleration * delta
	)
	velocity = global_position.direction_to(player.global_position) * current_magnet_speed

	if distance <= pickup_distance:
		_collect(player)


func _collect(collector: Node2D) -> void:
	if collected:
		return

	if not collector.has_method("try_add_artifact"):
		return
	if not bool(collector.call("try_add_artifact", artifact_id)):
		_reject_pickup(collector)
		return

	collected = true
	pickup_area.set_deferred("monitoring", false)
	queue_free()


func _reject_pickup(collector: Node2D) -> void:
	var horizontal_direction := signf(global_position.x - collector.global_position.x)
	if horizontal_direction == 0.0:
		horizontal_direction = -1.0 if randf() < 0.5 else 1.0
	velocity = Vector2(horizontal_direction * 210.0, -260.0)
	current_magnet_speed = 0.0
	magnet_delay_remaining = 1.25
	pickup_reject_time = 0.65
