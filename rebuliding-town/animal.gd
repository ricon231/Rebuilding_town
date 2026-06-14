extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal died

@export_category("Stats")
@export var max_health: int = 50
@export var move_speed: float = 35.0
@export var attack_power: int = 0

@export_category("Behavior")
@export var aggressive := false
@export var detection_distance: float = 180.0
@export var attack_distance: float = 48.0
@export var attack_cooldown: float = 1.4
@export var wander_distance: float = 90.0
@export var wander_change_interval: float = 2.5
@export var reverse_attack_effect := false

@export_category("Physics")
@export var gravity: float = 980.0
@export var maximum_fall_speed: float = 900.0

@export_category("Drops")
@export var coin_scene: PackedScene = preload("res://coin.tscn")
@export_range(0, 100, 1) var coin_drop_count: int = 1
@export var coin_scatter: Vector2 = Vector2(22.0, 8.0)
@export_range(0.0, 1.0, 0.01) var artifact_drop_chance := 0.2
@export var artifact_drop_scenes: Array[PackedScene] = [
	preload("res://artifacts/items/phoenix_pillow.tscn"),
	preload("res://artifacts/items/phoenix_vase.tscn"),
	preload("res://artifacts/items/phoenix_paintings.tscn"),
	preload("res://artifacts/items/octagonal_brush_holder.tscn"),
	preload("res://artifacts/items/deer_lunch_box.tscn"),
	preload("res://artifacts/items/zodiac_sundial.tscn"),
	preload("res://artifacts/items/round_textile.tscn"),
	preload("res://artifacts/items/longevity_pouch.tscn"),
	preload("res://artifacts/items/guardian_tile.tscn"),
	preload("res://artifacts/items/mother_of_pearl_brush_stand.tscn"),
]

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var health_bar: ProgressBar = $HealthBar

var health: int
var player: Node2D
var target_actor: Node2D
var spawn_position: Vector2
var facing_direction := 1.0
var wander_direction := 1.0
var wander_timer := 0.0
var cooldown_timer := 0.0
var attacking := false
var damage_applied := false
var dead := false
var raid_mode := false
var raid_destination := Vector2.ZERO


func _ready() -> void:
	health = max_health
	spawn_position = global_position
	player = get_tree().get_first_node_in_group("player") as Node2D
	wander_direction = -1.0 if randf() < 0.5 else 1.0
	wander_timer = randf_range(0.5, wander_change_interval)
	_apply_health_bar_style()
	body_sprite.play("move")
	_update_health_bar()


func _apply_health_bar_style() -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.16, 0.04, 0.04, 0.95)
	background.border_width_left = 1
	background.border_width_top = 1
	background.border_width_right = 1
	background.border_width_bottom = 1
	background.border_color = Color(0.08, 0.02, 0.02, 1.0)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.08, 0.08, 1.0)

	health_bar.add_theme_stylebox_override("background", background)
	health_bar.add_theme_stylebox_override("fill", fill)


func _physics_process(delta: float) -> void:
	if dead:
		return

	cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	_apply_gravity(delta)

	if attacking:
		velocity.x = 0.0
		move_and_slide()
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	if aggressive:
		target_actor = _find_nearest_target()
	if aggressive and is_instance_valid(target_actor):
		var target_distance := global_position.distance_to(target_actor.global_position)
		if target_distance <= attack_distance and cooldown_timer <= 0.0:
			_start_attack()
			return
		if target_distance <= detection_distance:
			_move_toward_target()
			return
	if raid_mode:
		_move_toward_raid_destination()
		return

	_wander(delta)


func _move_toward_target() -> void:
	var direction := signf(target_actor.global_position.x - global_position.x)
	if direction == 0.0:
		direction = facing_direction

	_set_facing(direction)
	velocity.x = direction * move_speed
	move_and_slide()
	_play_move()


func configure_raid(target_position: Vector2) -> void:
	raid_mode = true
	raid_destination = target_position


func _move_toward_raid_destination() -> void:
	var horizontal_distance := raid_destination.x - global_position.x
	if absf(horizontal_distance) <= 24.0:
		raid_mode = false
		spawn_position = raid_destination
		velocity.x = 0.0
		_play_move()
		return

	var direction := signf(horizontal_distance)
	_set_facing(direction)
	velocity.x = direction * move_speed
	move_and_slide()
	_play_move()


func _wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = wander_change_interval
		wander_direction = -1.0 if randf() < 0.5 else 1.0

	if absf(global_position.x - spawn_position.x) >= wander_distance:
		wander_direction = signf(spawn_position.x - global_position.x)

	_set_facing(wander_direction)
	velocity.x = wander_direction * move_speed * 0.45
	move_and_slide()
	_play_move()


func _start_attack() -> void:
	if not body_sprite.sprite_frames.has_animation("attack"):
		return

	attacking = true
	damage_applied = false
	velocity.x = 0.0
	body_sprite.play("attack")


func _on_body_sprite_frame_changed() -> void:
	if not attacking or body_sprite.animation != &"attack":
		return

	if body_sprite.frame == 2 and not damage_applied:
		damage_applied = true
		_play_attack_effect()

		if is_instance_valid(target_actor):
			var target_distance := global_position.distance_to(target_actor.global_position)
			if target_distance <= attack_distance * 1.35:
				if target_actor.has_method("take_damage"):
					target_actor.call("take_damage", attack_power, self)


func _on_body_sprite_animation_finished() -> void:
	if body_sprite.animation == &"attack":
		attacking = false
		cooldown_timer = attack_cooldown
		_play_move()


func _play_attack_effect() -> void:
	if attack_effect.sprite_frames == null:
		return
	if not attack_effect.sprite_frames.has_animation("effect"):
		return

	attack_effect.visible = true
	attack_effect.frame = 0
	attack_effect.play("effect")


func _on_attack_effect_animation_finished() -> void:
	attack_effect.visible = false


func _play_move() -> void:
	if body_sprite.animation != &"move":
		body_sprite.play("move")


func _set_facing(direction: float) -> void:
	facing_direction = direction
	body_sprite.flip_h = direction < 0.0
	attack_effect.flip_h = (direction > 0.0) if reverse_attack_effect else (direction < 0.0)
	attack_effect.position.x = absf(attack_effect.position.x) * direction


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		if velocity.y > 0.0:
			velocity.y = 0.0
		return

	velocity.y = minf(velocity.y + gravity * delta, maximum_fall_speed)


func _find_nearest_target() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	var candidates := get_tree().get_nodes_in_group("citizen")
	if is_instance_valid(player):
		candidates.append(player)

	for candidate in candidates:
		var actor := candidate as Node2D
		if not is_instance_valid(actor):
			continue
		var distance := global_position.distance_to(actor.global_position)
		if distance < nearest_distance:
			nearest = actor
			nearest_distance = distance
	return nearest


func take_damage(amount: int) -> void:
	if dead:
		return

	health = clampi(health - maxi(amount, 0), 0, max_health)
	health_changed.emit(health, max_health)
	_update_health_bar()

	if health <= 0:
		_die()


func _update_health_bar() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = health < max_health and health > 0


func _die() -> void:
	dead = true
	died.emit()
	_finish_death.call_deferred()


func _finish_death() -> void:
	if not is_inside_tree():
		return

	drop_items()
	var force_artifact_drop := false
	var current_scene := get_tree().current_scene
	if (
		current_scene != null
		and current_scene.has_method("claim_first_mob_artifact_drop")
	):
		force_artifact_drop = bool(
			current_scene.call("claim_first_mob_artifact_drop")
		)
	drop_artifact(force_artifact_drop)
	queue_free()


func drop_items() -> void:
	if coin_scene == null or coin_drop_count <= 0:
		return

	var drop_parent := get_tree().current_scene.get_node_or_null("Pickups")
	if drop_parent == null:
		drop_parent = get_tree().current_scene

	for coin_index in coin_drop_count:
		var coin := coin_scene.instantiate() as Node2D
		drop_parent.add_child(coin)
		coin.global_position = global_position + Vector2(
			randf_range(-coin_scatter.x, coin_scatter.x),
			randf_range(-coin_scatter.y, coin_scatter.y)
		)


func drop_artifact(force_drop := false) -> void:
	var effective_drop_chance := artifact_drop_chance
	if ArtifactCatalog.has_effect(&"deer_lunch_box"):
		effective_drop_chance += 0.2
	effective_drop_chance = clampf(effective_drop_chance, 0.0, 1.0)

	if (
		artifact_drop_scenes.is_empty()
		or (not force_drop and randf() > effective_drop_chance)
	):
		return

	var available_scenes: Array[PackedScene] = []
	for artifact_scene in artifact_drop_scenes:
		if artifact_scene == null:
			continue
		var preview := artifact_scene.instantiate()
		var preview_id := StringName(preview.get("artifact_id"))
		preview.free()
		if not ArtifactCatalog.is_registered(preview_id):
			available_scenes.append(artifact_scene)

	if available_scenes.is_empty():
		return

	var drop_parent := get_tree().current_scene.get_node_or_null("Pickups/ArtifactPickups")
	if drop_parent == null:
		drop_parent = get_tree().current_scene

	var artifact := available_scenes.pick_random().instantiate() as Node2D
	if artifact == null:
		return
	drop_parent.add_child(artifact)
	artifact.scale *= 0.5
	artifact.global_position = global_position + Vector2(0.0, -24.0)
