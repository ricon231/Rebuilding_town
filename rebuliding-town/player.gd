extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal coins_changed(current_coins: int)
signal artifact_inventory_changed(slots: Array[StringName])
signal died

@export_category("Player Stats")
@export var coins: int = 0
@export var attack_power: int = 10
@export var health: int = 100
@export var max_health: int = 100
@export var move_speed := 220.0

@export_category("Movement")
@export var acceleration := 1800.0
@export var deceleration := 2200.0
@export var gravity: float = 980.0
@export var maximum_fall_speed: float = 900.0
@export var jump_force: float = 430.0
@export_range(0.0, 2.0, 0.05) var damage_invulnerability_duration := 0.55

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_trail: AnimatedSprite2D = $SwordTrail
@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var thrust_effect: AnimatedSprite2D = $ThrustEffect
@onready var thrust_hitbox: Area2D = $ThrustHitbox

var facing_direction := 1.0
var attacking := false
var jump_was_pressed := false
var hit_targets: Array[Node] = []
var current_attack_damage := 0
var artifact_slots: Array[StringName] = [&"", &""]
var base_attack_power: int
var base_max_health: int
var base_move_speed: float
var town_attack_bonus_ratio := 0.0
var invulnerable_time_remaining := 0.0
var daily_invulnerability_used := false
var passive_coin_elapsed := 0.0
var dead := false
var attack_preparing := false
var attack_prepare_time_remaining := 0.0
var sword_trail_tween: Tween
var thrust_preparing := false
var thrust_dashing := false
var thrust_recovering := false
var thrust_invulnerable := false
var thrust_time_remaining := 0.0
var thrust_dash_speed := 0.0
var thrust_dash_distance := 0.0

const BASE_TRAIL_SCALE := Vector2(0.64, 0.64)
const BASE_HITBOX_SCALE := Vector2.ONE
const PLAYER_ATTACK_VISUAL_BOTTOM := 28.5
const SWORD_TRAIL_VISUAL_BOTTOM_FROM_CENTER := 81.0
const SWORD_TRAIL_FRAME := 2
const SWORD_TRAIL_FADE_DURATION := 0.2
const LOW_HEALTH_INVULNERABILITY_DURATION := 3.0
const PASSIVE_COIN_INTERVAL := 5.0
const FIRST_ATTACK_PREPARE_DURATION := 0.2
const THRUST_PREPARE_DURATION := 0.2
const THRUST_DASH_DURATION := 0.1
const THRUST_RECOVER_DURATION := 0.18
const THRUST_TRAIL_FRAME := 1
const THRUST_TRAIL_FADE_DURATION := 0.2


func _ready() -> void:
	base_attack_power = attack_power
	base_max_health = max_health
	base_move_speed = move_speed
	ArtifactCatalog.artifact_registered.connect(_on_artifact_registered)
	_apply_artifact_effects()
	health = clampi(health, 0, max_health)
	animated_sprite.play("idle")
	health_changed.emit(health, max_health)
	coins_changed.emit(coins)
	artifact_inventory_changed.emit(artifact_slots.duplicate())


func _physics_process(delta: float) -> void:
	if dead:
		return

	invulnerable_time_remaining = maxf(
		invulnerable_time_remaining - delta,
		0.0
	)
	_update_passive_coin_income(delta)

	if attack_preparing:
		_process_attack_prepare(delta)
		return
	if thrust_preparing:
		_process_thrust_prepare(delta)
		return
	if thrust_dashing:
		_process_thrust_dash(delta)
		return
	if thrust_recovering:
		_process_thrust_recover(delta)
		return

	var direction := _get_horizontal_input()
	var target_velocity := direction * move_speed
	var jump_pressed := _is_jump_pressed()

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, maximum_fall_speed)
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if jump_pressed and not jump_was_pressed and is_on_floor() and not attacking:
		velocity.y = -jump_force

	jump_was_pressed = jump_pressed

	if attacking:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	elif direction != 0.0:
		velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	move_and_slide()

	if attacking:
		pass
	elif not is_on_floor():
		_show_jump_frame()
	elif direction != 0.0:
		facing_direction = direction
		_play_animation("run")
	else:
		_play_animation("idle")

	animated_sprite.flip_h = facing_direction < 0.0
	sword_trail.flip_h = facing_direction > 0.0
	sword_trail.position.x = absf(sword_trail.position.x) * facing_direction
	sword_hitbox.position.x = absf(sword_hitbox.position.x) * facing_direction


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_attack()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_start_thrust()
			get_viewport().set_input_as_handled()


func _start_attack() -> void:
	if attacking:
		return

	attacking = true
	hit_targets.clear()
	velocity.x = 0.0
	sword_trail.scale = BASE_TRAIL_SCALE
	_align_sword_trail_bottom()
	sword_hitbox.scale = BASE_HITBOX_SCALE
	current_attack_damage = attack_power
	attack_preparing = true
	attack_prepare_time_remaining = FIRST_ATTACK_PREPARE_DURATION
	animated_sprite.play(&"attack_prepare")
	sword_trail.visible = false
	sword_hitbox.set_deferred("monitoring", false)


func _process_attack_prepare(delta: float) -> void:
	attack_prepare_time_remaining -= delta
	_apply_gravity(delta)
	velocity.x = 0.0
	move_and_slide()
	animated_sprite.flip_h = facing_direction < 0.0
	if attack_prepare_time_remaining <= 0.0:
		animated_sprite.play(&"attack")
		_begin_sword_attack()


func _begin_sword_attack() -> void:
	attack_preparing = false
	attack_prepare_time_remaining = 0.0
	if sword_trail_tween != null:
		sword_trail_tween.kill()
	sword_trail.visible = true
	sword_trail.animation = &"slash"
	sword_trail.frame = SWORD_TRAIL_FRAME
	sword_trail.pause()
	sword_trail.modulate.a = 1.0
	sword_hitbox.set_deferred("monitoring", true)

	sword_trail_tween = sword_trail.create_tween()
	sword_trail_tween.set_trans(Tween.TRANS_LINEAR)
	sword_trail_tween.tween_property(
		sword_trail,
		"modulate:a",
		0.0,
		SWORD_TRAIL_FADE_DURATION
	)
	sword_trail_tween.tween_callback(_finish_sword_attack)


func _align_sword_trail_bottom() -> void:
	sword_trail.position.y = (
		PLAYER_ATTACK_VISUAL_BOTTOM
		- SWORD_TRAIL_VISUAL_BOTTOM_FROM_CENTER
		* absf(sword_trail.scale.y)
	)


func _finish_sword_attack() -> void:
	sword_trail.visible = false
	sword_trail.modulate.a = 1.0
	sword_trail_tween = null
	sword_hitbox.set_deferred("monitoring", false)
	attacking = false


func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if not attacking or body in hit_targets:
		return
	if not body.has_method("take_damage"):
		return

	hit_targets.append(body)
	if body.is_in_group("citizen"):
		return
	body.take_damage(current_attack_damage)


func _start_thrust() -> void:
	if attacking or not is_on_floor():
		return

	var input_direction := _get_horizontal_input()
	if input_direction != 0.0:
		facing_direction = input_direction

	attacking = true
	thrust_preparing = true
	thrust_recovering = false
	thrust_time_remaining = THRUST_PREPARE_DURATION
	current_attack_damage = attack_power
	hit_targets.clear()
	velocity.x = 0.0
	animated_sprite.play(&"thrust_prepare")
	_update_thrust_orientation()


func _process_thrust_prepare(delta: float) -> void:
	thrust_time_remaining -= delta
	_apply_gravity(delta)
	velocity.x = 0.0
	move_and_slide()
	_update_thrust_orientation()
	if thrust_time_remaining <= 0.0:
		_begin_thrust_dash()


func _begin_thrust_dash() -> void:
	thrust_preparing = false
	thrust_dashing = true
	thrust_invulnerable = true
	thrust_time_remaining = THRUST_DASH_DURATION
	thrust_dash_distance = _get_thrust_effect_width()
	thrust_dash_speed = thrust_dash_distance / THRUST_DASH_DURATION
	animated_sprite.play(&"thrust_attack")
	_spawn_thrust_trail()
	thrust_hitbox.set_deferred("monitoring", true)
	_update_thrust_orientation()


func _process_thrust_dash(delta: float) -> void:
	var dash_step := minf(delta, thrust_time_remaining)
	thrust_time_remaining -= delta
	_apply_gravity(delta)
	velocity.x = (
		facing_direction
		* thrust_dash_speed
		* dash_step
		/ delta
	)
	var previous_x := global_position.x
	move_and_slide()
	_update_thrust_orientation()

	var expected_distance := absf(velocity.x) * delta
	var blocked := (
		expected_distance > 0.0
		and absf(global_position.x - previous_x) < expected_distance * 0.1
	)
	if thrust_time_remaining <= 0.0 or blocked:
		_begin_thrust_recover()


func _begin_thrust_recover() -> void:
	thrust_preparing = false
	thrust_dashing = false
	thrust_invulnerable = false
	thrust_recovering = true
	thrust_time_remaining = THRUST_RECOVER_DURATION
	velocity.x = 0.0
	thrust_hitbox.set_deferred("monitoring", false)
	animated_sprite.play(&"thrust_prepare")
	_update_thrust_orientation()


func _process_thrust_recover(delta: float) -> void:
	thrust_time_remaining -= delta
	_apply_gravity(delta)
	velocity.x = 0.0
	move_and_slide()
	_update_thrust_orientation()
	if thrust_time_remaining <= 0.0:
		_finish_thrust()


func _finish_thrust() -> void:
	thrust_preparing = false
	thrust_dashing = false
	thrust_recovering = false
	thrust_invulnerable = false
	thrust_time_remaining = 0.0
	velocity.x = 0.0
	attacking = false
	_play_animation(&"idle")


func _update_thrust_orientation() -> void:
	animated_sprite.flip_h = facing_direction < 0.0
	thrust_hitbox.position.x = absf(thrust_hitbox.position.x) * facing_direction


func _get_thrust_effect_width() -> float:
	var effect_texture := thrust_effect.sprite_frames.get_frame_texture(
		&"thrust",
		THRUST_TRAIL_FRAME
	)
	if effect_texture == null:
		return 0.0
	return effect_texture.get_width() * absf(thrust_effect.scale.x)


func _spawn_thrust_trail() -> void:
	var trail := thrust_effect.duplicate() as AnimatedSprite2D
	get_parent().add_child(trail)
	var effect_offset := Vector2(
		absf(thrust_effect.position.x) * facing_direction,
		thrust_effect.position.y
	)
	trail.global_position = to_global(effect_offset)
	trail.global_rotation = thrust_effect.global_rotation
	trail.global_scale = thrust_effect.global_scale
	trail.flip_h = facing_direction < 0.0
	trail.visible = true
	trail.animation = &"thrust"
	trail.frame = THRUST_TRAIL_FRAME
	trail.pause()
	trail.modulate.a = 1.0

	var fade_tween := trail.create_tween()
	fade_tween.set_trans(Tween.TRANS_LINEAR)
	fade_tween.tween_property(
		trail,
		"modulate:a",
		0.0,
		THRUST_TRAIL_FADE_DURATION
	)
	fade_tween.tween_callback(trail.queue_free)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, maximum_fall_speed)
	elif velocity.y > 0.0:
		velocity.y = 0.0


func _on_thrust_hitbox_body_entered(body: Node2D) -> void:
	if not thrust_dashing or body in hit_targets:
		return
	if not body.has_method("take_damage"):
		return

	hit_targets.append(body)
	if body.is_in_group("citizen"):
		return
	body.take_damage(current_attack_damage)


func _get_horizontal_input() -> float:
	var direction := 0.0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0

	return direction


func _is_jump_pressed() -> bool:
	return (
		Input.is_key_pressed(KEY_SPACE)
		or Input.is_key_pressed(KEY_W)
		or Input.is_key_pressed(KEY_UP)
	)


func _play_animation(animation_name: StringName) -> void:
	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)


func _show_jump_frame() -> void:
	if animated_sprite.animation != &"run":
		animated_sprite.play(&"run")
	animated_sprite.pause()
	animated_sprite.frame = 3


func take_damage(amount: int, _attacker: Node = null) -> void:
	if dead or thrust_invulnerable or invulnerable_time_remaining > 0.0:
		return

	health = clampi(health - max(amount, 0), 0, max_health)
	invulnerable_time_remaining = damage_invulnerability_duration
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()
		return
	if (
		ArtifactCatalog.has_effect(&"longevity_pouch")
		and not daily_invulnerability_used
		and health <= ceili(max_health * 0.3)
	):
		daily_invulnerability_used = true
		invulnerable_time_remaining = LOW_HEALTH_INVULNERABILITY_DURATION


func heal(amount: int) -> void:
	if dead:
		return
	health = clampi(health + max(amount, 0), 0, max_health)
	health_changed.emit(health, max_health)


func get_periodic_heal_amount() -> int:
	var amount := 1
	if ArtifactCatalog.has_effect(&"phoenix_pillow"):
		amount += 1
	if ArtifactCatalog.has_effect(&"phoenix_vase"):
		amount += 3
	if ArtifactCatalog.has_effect(&"round_textile"):
		amount += 5
	return amount


func can_recover_at_night() -> bool:
	return ArtifactCatalog.has_effect(&"phoenix_paintings")


func reset_daily_artifact_effects() -> void:
	daily_invulnerability_used = false
	invulnerable_time_remaining = 0.0


func add_coins(amount: int) -> void:
	coins = max(coins + amount, 0)
	coins_changed.emit(coins)


func spend_coins(amount: int) -> bool:
	if amount < 0 or coins < amount:
		return false

	coins -= amount
	coins_changed.emit(coins)
	return true


func try_add_artifact(artifact_id: StringName) -> bool:
	for slot_index in artifact_slots.size():
		if artifact_slots[slot_index] == &"":
			artifact_slots[slot_index] = artifact_id
			artifact_inventory_changed.emit(artifact_slots.duplicate())
			return true
	return false


func get_artifact_in_slot(slot_index: int) -> StringName:
	if slot_index < 0 or slot_index >= artifact_slots.size():
		return &""
	return artifact_slots[slot_index]


func remove_artifact_from_slot(slot_index: int) -> StringName:
	if slot_index < 0 or slot_index >= artifact_slots.size():
		return &""

	var artifact_id := artifact_slots[slot_index]
	artifact_slots[slot_index] = &""
	artifact_inventory_changed.emit(artifact_slots.duplicate())
	return artifact_id


func get_attack_damage() -> int:
	return attack_power


func set_town_attack_bonus(bonus_ratio: float) -> void:
	town_attack_bonus_ratio = maxf(bonus_ratio, 0.0)
	_apply_artifact_effects()


func get_save_data() -> Dictionary:
	var saved_slots: Array[String] = []
	for artifact_id in artifact_slots:
		saved_slots.append(str(artifact_id))
	return {
		"position": [global_position.x, global_position.y],
		"coins": coins,
		"health": health,
		"facing_direction": facing_direction,
		"artifact_slots": saved_slots,
		"daily_invulnerability_used": daily_invulnerability_used,
		"passive_coin_elapsed": passive_coin_elapsed,
	}


func apply_save_data(data: Dictionary) -> void:
	_cancel_attack_state()
	var saved_position: Array = data.get("position", [])
	if saved_position.size() >= 2:
		global_position = Vector2(
			float(saved_position[0]),
			float(saved_position[1])
		)
	coins = maxi(int(data.get("coins", coins)), 0)
	facing_direction = -1.0 if float(
		data.get("facing_direction", facing_direction)
	) < 0.0 else 1.0

	artifact_slots = [&"", &""]
	var saved_slots: Array = data.get("artifact_slots", [])
	for slot_index in mini(saved_slots.size(), artifact_slots.size()):
		artifact_slots[slot_index] = StringName(str(saved_slots[slot_index]))

	daily_invulnerability_used = bool(
		data.get("daily_invulnerability_used", false)
	)
	passive_coin_elapsed = maxf(
		float(data.get("passive_coin_elapsed", 0.0)),
		0.0
	)
	_apply_artifact_effects()
	health = clampi(int(data.get("health", max_health)), 0, max_health)
	dead = false
	animated_sprite.rotation = 0.0
	animated_sprite.position.y = 0.0
	animated_sprite.flip_h = facing_direction < 0.0
	_play_animation(&"idle")
	health_changed.emit(health, max_health)
	coins_changed.emit(coins)
	artifact_inventory_changed.emit(artifact_slots.duplicate())


func _cancel_attack_state() -> void:
	attacking = false
	attack_preparing = false
	attack_prepare_time_remaining = 0.0
	thrust_preparing = false
	thrust_dashing = false
	thrust_recovering = false
	thrust_invulnerable = false
	thrust_time_remaining = 0.0
	velocity = Vector2.ZERO
	if sword_trail_tween != null:
		sword_trail_tween.kill()
		sword_trail_tween = null
	sword_trail.visible = false
	sword_trail.modulate.a = 1.0
	sword_hitbox.set_deferred("monitoring", false)
	thrust_hitbox.set_deferred("monitoring", false)


func _on_artifact_registered(_artifact_id: StringName) -> void:
	_apply_artifact_effects()


func _apply_artifact_effects() -> void:
	var previous_max_health := max_health
	var health_bonus := 0
	var attack_bonus_ratio := 0.0
	var speed_bonus_ratio := 0.0

	if ArtifactCatalog.has_effect(&"phoenix_pillow"):
		health_bonus += 50
	if ArtifactCatalog.has_effect(&"phoenix_vase"):
		health_bonus += 25
	if ArtifactCatalog.has_effect(&"zodiac_sundial"):
		health_bonus += 10
		attack_bonus_ratio += 0.2
		speed_bonus_ratio += 0.2
	if ArtifactCatalog.has_effect(&"guardian_tile"):
		attack_bonus_ratio += 0.6

	max_health = base_max_health + health_bonus
	attack_power = roundi(
		base_attack_power
		* (1.0 + attack_bonus_ratio + town_attack_bonus_ratio)
	)
	move_speed = base_move_speed * (1.0 + speed_bonus_ratio)

	if max_health > previous_max_health:
		health += max_health - previous_max_health
	health = clampi(health, 0, max_health)
	health_changed.emit(health, max_health)


func _update_passive_coin_income(delta: float) -> void:
	if not ArtifactCatalog.has_effect(&"mother_of_pearl_brush_stand"):
		passive_coin_elapsed = 0.0
		return

	passive_coin_elapsed += delta
	while passive_coin_elapsed >= PASSIVE_COIN_INTERVAL:
		passive_coin_elapsed -= PASSIVE_COIN_INTERVAL
		add_coins(1)


func _die() -> void:
	dead = true
	attacking = false
	if sword_trail_tween != null:
		sword_trail_tween.kill()
		sword_trail_tween = null
	attack_preparing = false
	attack_prepare_time_remaining = 0.0
	thrust_preparing = false
	thrust_dashing = false
	thrust_recovering = false
	thrust_invulnerable = false
	velocity = Vector2.ZERO
	sword_trail.visible = false
	sword_trail.modulate.a = 1.0
	sword_hitbox.set_deferred("monitoring", false)
	thrust_hitbox.set_deferred("monitoring", false)
	animated_sprite.play(&"idle")
	animated_sprite.pause()
	animated_sprite.frame = 0

	var fall_direction := 1.0 if facing_direction >= 0.0 else -1.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		animated_sprite,
		"rotation",
		fall_direction * PI * 0.5,
		0.45
	)
	tween.parallel().tween_property(
		animated_sprite,
		"position:y",
		18.0,
		0.45
	)
	tween.tween_callback(died.emit)
