extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal died

enum State {
	STANDING,
	WALKING,
	AFRAID,
	DEAD,
}

const SPRITE_SHEET := preload("res://assets/citizen_commoner_animation_sheet.png")
const FRAME_SIZE := Vector2(192.0, 192.0)

@export_category("Appearance")
@export_range(-1, 4, 1) var clothing_variant := -1

@export_category("Stats")
@export var max_health := 40
@export var move_speed := 38.0
@export var flee_speed_multiplier := 1.6

@export_category("Behavior")
@export var fear_distance := 170.0
@export var wander_distance := 120.0
@export var standing_duration := Vector2(1.5, 4.0)
@export var walking_duration := Vector2(1.5, 3.5)
@export_range(0.0, 1.0, 0.05) var walking_chance := 0.55

@export_category("Physics")
@export var gravity := 980.0
@export var maximum_fall_speed := 900.0
@export var death_launch_speed := Vector2(230.0, 340.0)
@export var corpse_duration := 10.0

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health := 10
var state := State.STANDING
var spawn_position := Vector2.ZERO
var state_timer := 0.0
var wander_direction := 1.0
var facing_direction := 1.0
var death_landed := false
var corpse_timer := 0.0


func _ready() -> void:
	health = max_health
	spawn_position = global_position
	if clothing_variant < 0:
		clothing_variant = randi_range(0, 4)
	_build_sprite_frames()
	_choose_random_state()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		_update_death(delta)
		return

	_apply_gravity(delta)
	var hostile := _find_nearest_hostile()
	if is_instance_valid(hostile):
		_enter_afraid(hostile)
	else:
		_update_normal_behavior(delta)

	move_and_slide()


func _update_normal_behavior(delta: float) -> void:
	if state == State.AFRAID:
		_choose_random_state()

	state_timer -= delta
	if state_timer <= 0.0:
		_choose_random_state()

	if state == State.WALKING:
		if absf(global_position.x - spawn_position.x) >= wander_distance:
			wander_direction = signf(spawn_position.x - global_position.x)
		_set_facing(wander_direction)
		velocity.x = wander_direction * move_speed
		_play_animation(&"walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		_play_animation(&"stand")


func _choose_random_state() -> void:
	if randf() < walking_chance:
		state = State.WALKING
		wander_direction = -1.0 if randf() < 0.5 else 1.0
		_set_facing(wander_direction)
		state_timer = randf_range(walking_duration.x, walking_duration.y)
		_play_animation(&"walk")
	else:
		state = State.STANDING
		state_timer = randf_range(standing_duration.x, standing_duration.y)
		velocity.x = 0.0
		_play_animation(&"stand")


func _enter_afraid(hostile: Node2D) -> void:
	state = State.AFRAID
	var flee_direction := signf(global_position.x - hostile.global_position.x)
	if flee_direction == 0.0:
		flee_direction = -facing_direction
	_set_facing(flee_direction)
	velocity.x = flee_direction * move_speed * flee_speed_multiplier
	_play_animation(&"afraid")


func _find_nearest_hostile() -> Node2D:
	var nearest: Node2D
	var nearest_distance := fear_distance
	for candidate in get_tree().get_nodes_in_group("hostile_animal"):
		var hostile := candidate as Node2D
		if not is_instance_valid(hostile):
			continue
		var distance := global_position.distance_to(hostile.global_position)
		if distance <= nearest_distance:
			nearest = hostile
			nearest_distance = distance
	return nearest


func take_damage(amount: int, attacker: Node = null) -> void:
	if state == State.DEAD:
		return

	health = clampi(health - maxi(amount, 0), 0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0:
		_die(attacker as Node2D)


func _die(attacker: Node2D) -> void:
	state = State.DEAD
	remove_from_group("citizen")
	collision_layer = 0
	body_sprite.stop()
	body_sprite.animation = &"stand"
	body_sprite.frame = 0
	body_sprite.rotation = deg_to_rad(90.0)
	body_sprite.modulate = Color(1.0, 0.22, 0.22, 1.0)

	var launch_direction := -facing_direction
	if is_instance_valid(attacker):
		launch_direction = signf(global_position.x - attacker.global_position.x)
	if launch_direction == 0.0:
		launch_direction = 1.0

	velocity = Vector2(
		launch_direction * death_launch_speed.x,
		-death_launch_speed.y
	)
	floor_snap_length = 0.0
	died.emit()


func _update_death(delta: float) -> void:
	if not death_landed:
		velocity.y = minf(velocity.y + gravity * delta, maximum_fall_speed)
		move_and_slide()
		if is_on_floor() and velocity.y >= 0.0:
			death_landed = true
			velocity = Vector2.ZERO
			corpse_timer = corpse_duration
			collision_shape.set_deferred("disabled", true)
		return

	corpse_timer -= delta
	if corpse_timer <= 0.0:
		queue_free()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		if velocity.y > 0.0:
			velocity.y = 0.0
		return
	velocity.y = minf(velocity.y + gravity * delta, maximum_fall_speed)


func _set_facing(direction: float) -> void:
	if direction == 0.0:
		return
	facing_direction = direction
	body_sprite.flip_h = direction < 0.0


func _play_animation(animation_name: StringName) -> void:
	if body_sprite.animation != animation_name or not body_sprite.is_playing():
		body_sprite.play(animation_name)


func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"stand", [0], 1.0)
	_add_animation(frames, &"walk", [1, 2, 3, 4, 5, 6], 8.0)
	_add_animation(frames, &"afraid", [7, 8], 5.0)
	body_sprite.sprite_frames = frames


func _add_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	columns: Array,
	speed: float
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, speed)
	for column in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = SPRITE_SHEET
		atlas.region = Rect2(
			float(column) * FRAME_SIZE.x,
			float(clothing_variant) * FRAME_SIZE.y,
			FRAME_SIZE.x,
			FRAME_SIZE.y
		)
		frames.add_frame(animation_name, atlas)
