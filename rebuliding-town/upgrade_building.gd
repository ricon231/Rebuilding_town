extends Node2D

signal upgraded(new_stage: int)
signal maximum_stage_reached
signal upgrade_failed(required_coins: int)

const E_KEY_SCENE := preload("res://e_key.tscn")
const UPGRADE_COIN_TEXTURE := preload(
	"res://assets/coin_old_square_hole_gray.png"
)
const SMALL_CONSTRUCTION_COVER := preload(
	"res://assets/joseon_construction_cover_small.png"
)
const LARGE_CONSTRUCTION_COVER := preload(
	"res://assets/joseon_construction_cover_large.png"
)

@export_category("Building")
@export_range(0, 10, 1) var starting_stage: int = 0
@export var upgrade_costs: Array[int] = [1, 3, 5, 7]
@export_range(0.5, 10.0, 0.1) var upgrade_duration := 3.0
@export var construction_cover: Texture2D

@export_category("Interaction")
@export var interaction_width: float = 120.0
@export var interaction_height: float = 72.0
@export var prompt_gap: float = 18.0
@export_flags_2d_physics var player_collision_mask := 2
@export_category("Upgrade Cost Display")
@export_range(1, 20, 1) var coins_per_row := 5
@export var coin_display_scale := 0.18
@export var coin_horizontal_gap := 2.0
@export var coin_vertical_gap := 3.0
@export var coin_height_multiplier := 1.5

@onready var stage_sprites: Array[Node] = $Stages.get_children()
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/CollisionShape2D
@onready var prompt_anchor: Node2D = $PromptAnchor

var current_stage: int = 0
var player_in_range := false
var e_prompt: Node2D
var upgrade_coin_display: Node2D
var interacting_player: Node
var upgrading := false
var construction_progress := 0.0
var construction_size := Vector2.ZERO
var construction_center := Vector2.ZERO
var construction_wall: Node2D
var active_construction_cover: Texture2D


func _ready() -> void:
	add_to_group("upgrade_building")
	upgrade_failed.connect(_on_upgrade_failed)
	current_stage = clampi(starting_stage, 0, max(stage_sprites.size() - 1, 0))
	_create_construction_wall()
	_configure_interaction_area()
	_update_building()
	_refresh_interaction_state.call_deferred()


func _physics_process(_delta: float) -> void:
	_refresh_interaction_state()


func _unhandled_key_input(event: InputEvent) -> void:
	_refresh_interaction_state()
	if upgrading or interacting_player == null or _is_maximum_stage():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E or event.keycode == KEY_E:
			_upgrade()
			get_viewport().set_input_as_handled()


func _upgrade() -> void:
	var upgrade_cost := _get_upgrade_cost()
	if not _spend_upgrade_cost(upgrade_cost):
		upgrade_failed.emit(upgrade_cost)
		return

	_start_construction()


func _start_construction() -> void:
	upgrading = true
	_remove_e_prompt()
	_prepare_construction_wall()

	var rise_duration := minf(0.65, upgrade_duration * 0.3)
	var lower_duration := rise_duration
	var covered_duration := maxf(
		upgrade_duration - rise_duration - lower_duration,
		0.0
	)
	var tween := create_tween()
	tween.tween_method(_set_construction_progress, 0.0, 1.0, rise_duration)
	tween.tween_callback(_complete_upgrade_stage)
	tween.tween_interval(covered_duration)
	tween.tween_method(_set_construction_progress, 1.0, 0.0, lower_duration)
	tween.tween_callback(_finish_construction)


func _complete_upgrade_stage() -> void:
	current_stage += 1
	_update_building()
	upgraded.emit(current_stage + 1)

	if _is_maximum_stage():
		maximum_stage_reached.emit()


func _finish_construction() -> void:
	upgrading = false
	construction_progress = 0.0
	construction_wall.visible = false
	construction_wall.queue_redraw()

	if player_in_range and not _is_maximum_stage():
		_create_e_prompt()


func _create_construction_wall() -> void:
	construction_wall = Node2D.new()
	construction_wall.name = "ConstructionWall"
	construction_wall.z_index = 4000
	construction_wall.z_as_relative = false
	construction_wall.visible = false
	construction_wall.draw.connect(_draw_construction_wall)
	add_child(construction_wall)


func _prepare_construction_wall() -> void:
	var current_sprite := stage_sprites[current_stage] as Sprite2D
	var next_stage_index := mini(current_stage + 1, stage_sprites.size() - 1)
	var next_sprite := stage_sprites[next_stage_index] as Sprite2D
	var current_size := _get_sprite_display_size(current_sprite)
	var next_size := _get_sprite_display_size(next_sprite)
	var left := minf(
		current_sprite.position.x - current_size.x * 0.5,
		next_sprite.position.x - next_size.x * 0.5
	)
	var right := maxf(
		current_sprite.position.x + current_size.x * 0.5,
		next_sprite.position.x + next_size.x * 0.5
	)
	var top := minf(
		current_sprite.position.y - current_size.y * 0.5,
		next_sprite.position.y - next_size.y * 0.5
	)
	var bottom := maxf(
		current_sprite.position.y + current_size.y * 0.5,
		next_sprite.position.y + next_size.y * 0.5
	)

	construction_size = Vector2(
		right - left + 24.0,
		bottom - top + 16.0
	)
	construction_center = Vector2(
		(left + right) * 0.5,
		(top + bottom) * 0.5
	)
	active_construction_cover = construction_cover
	if active_construction_cover == null:
		active_construction_cover = (
			LARGE_CONSTRUCTION_COVER
			if construction_size.x >= 300.0
			else SMALL_CONSTRUCTION_COVER
		)
	construction_progress = 0.0
	construction_wall.visible = true
	construction_wall.queue_redraw()


func _get_sprite_display_size(sprite: Sprite2D) -> Vector2:
	if sprite == null or sprite.texture == null:
		return Vector2(interaction_width, interaction_height)
	return Vector2(sprite.texture.get_size()) * sprite.scale.abs()


func _set_construction_progress(value: float) -> void:
	construction_progress = clampf(value, 0.0, 1.0)
	construction_wall.queue_redraw()


func _draw_construction_wall() -> void:
	if construction_progress <= 0.0 or construction_size == Vector2.ZERO:
		return

	var bottom := construction_center.y + construction_size.y * 0.5
	var visible_height := construction_size.y * construction_progress
	var top := bottom - visible_height
	var left := construction_center.x - construction_size.x * 0.5
	if active_construction_cover == null:
		return

	var texture_size := Vector2(active_construction_cover.get_size())
	var source_height := texture_size.y * construction_progress
	var source_rect := Rect2(
		0.0,
		texture_size.y - source_height,
		texture_size.x,
		source_height
	)
	var destination_rect := Rect2(
		left,
		top,
		construction_size.x,
		visible_height
	)
	construction_wall.draw_texture_rect_region(
		active_construction_cover,
		destination_rect,
		source_rect
	)


func _update_building() -> void:
	if stage_sprites.is_empty():
		_remove_e_prompt()
		return

	for stage_index in stage_sprites.size():
		stage_sprites[stage_index].visible = stage_index == current_stage

	var current_sprite := stage_sprites[current_stage] as Sprite2D
	var building_size := _get_sprite_display_size(current_sprite)
	var building_bottom := current_sprite.position.y + building_size.y * 0.5
	interaction_shape.position.y = (
		building_bottom - interaction_height * 0.5
	)
	prompt_anchor.position = Vector2(
		current_sprite.position.x,
		building_bottom + prompt_gap
	)
	if player_in_range and not upgrading and not _is_maximum_stage():
		_create_e_prompt()
	else:
		_remove_e_prompt()


func _configure_interaction_area() -> void:
	interaction_area.collision_layer = 0
	interaction_area.collision_mask = player_collision_mask
	interaction_area.monitoring = true

	var rectangle := interaction_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		interaction_shape.shape = rectangle

	rectangle.size = Vector2(interaction_width, interaction_height)


func _refresh_interaction_state() -> void:
	if not is_instance_valid(interaction_area):
		return

	var overlapping_player: Node2D
	for body in interaction_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			overlapping_player = body as Node2D
			break

	var was_in_range := player_in_range
	player_in_range = is_instance_valid(overlapping_player)
	interacting_player = overlapping_player

	if player_in_range and not upgrading and not _is_maximum_stage():
		_create_e_prompt()
	elif was_in_range or is_instance_valid(e_prompt):
		_remove_e_prompt()


func _is_maximum_stage() -> bool:
	return stage_sprites.is_empty() or current_stage >= stage_sprites.size() - 1


func _get_upgrade_cost() -> int:
	if upgrade_costs.is_empty():
		return 0

	var cost_index := mini(current_stage, upgrade_costs.size() - 1)
	return maxi(upgrade_costs[cost_index], 0)


func apply_saved_stage(stage: int) -> void:
	if upgrading:
		upgrading = false
	current_stage = clampi(stage, 0, max(stage_sprites.size() - 1, 0))
	construction_progress = 0.0
	if is_instance_valid(construction_wall):
		construction_wall.visible = false
		construction_wall.queue_redraw()
	_update_building()
	_refresh_interaction_state.call_deferred()


func _spend_upgrade_cost(cost: int) -> bool:
	if cost <= 0:
		return true

	if not is_instance_valid(interacting_player):
		interacting_player = get_tree().get_first_node_in_group("player")
	if interacting_player == null or not interacting_player.has_method("spend_coins"):
		return false

	return bool(interacting_player.call("spend_coins", cost))


func _on_upgrade_failed(required_coins: int) -> void:
	var hud := get_tree().get_first_node_in_group("player_hud")
	if hud == null or not hud.has_method("show_message"):
		return
	var current_coins := 0
	if is_instance_valid(interacting_player):
		current_coins = maxi(int(interacting_player.get("coins")), 0)
	hud.call(
		"show_message",
		"엽전이 부족합니다. 필요 %d개 · 보유 %d개" % [
			required_coins,
			current_coins,
		]
	)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_refresh_interaction_state.call_deferred()


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_refresh_interaction_state.call_deferred()


func _create_e_prompt() -> void:
	if is_instance_valid(e_prompt):
		return
	e_prompt = E_KEY_SCENE.instantiate() as Node2D
	prompt_anchor.add_child(e_prompt)
	e_prompt.position = Vector2.ZERO
	_create_upgrade_cost_coins()


func _create_upgrade_cost_coins() -> void:
	var upgrade_cost := _get_upgrade_cost()
	if upgrade_cost <= 0:
		return

	_remove_upgrade_cost_coins()
	upgrade_coin_display = Node2D.new()
	upgrade_coin_display.name = "UpgradeCostCoins"
	upgrade_coin_display.z_index = 4096
	upgrade_coin_display.z_as_relative = false
	add_child(upgrade_coin_display)

	var current_sprite := stage_sprites[current_stage] as Sprite2D
	var building_size := _get_sprite_display_size(current_sprite)
	var ground_y := current_sprite.position.y + building_size.y * 0.5
	var player_height := _get_player_display_height()
	upgrade_coin_display.position = Vector2(
		current_sprite.position.x,
		ground_y - player_height * coin_height_multiplier
	)

	var texture_size := Vector2(UPGRADE_COIN_TEXTURE.get_size())
	var coin_size := texture_size * coin_display_scale
	var horizontal_step := coin_size.x + coin_horizontal_gap
	var vertical_step := coin_size.y + coin_vertical_gap
	var row_count := ceili(float(upgrade_cost) / float(coins_per_row))

	for row_index in row_count:
		var row_start := row_index * coins_per_row
		var coins_in_row := mini(coins_per_row, upgrade_cost - row_start)
		var row_width := float(coins_in_row - 1) * horizontal_step

		for column_index in coins_in_row:
			var coin := Sprite2D.new()
			coin.name = "UpgradeCoin%d" % (row_start + column_index + 1)
			coin.texture = UPGRADE_COIN_TEXTURE
			coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			coin.scale = Vector2.ONE * coin_display_scale
			coin.position = Vector2(
				float(column_index) * horizontal_step - row_width * 0.5,
				float(row_index) * vertical_step
			)
			upgrade_coin_display.add_child(coin)


func _get_player_display_height() -> float:
	var player_node := interacting_player as Node
	if not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("player")
	if player_node == null:
		return 61.0

	var player_sprite := player_node.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D
	if player_sprite == null or player_sprite.sprite_frames == null:
		return 61.0

	var frame_texture := player_sprite.sprite_frames.get_frame_texture(
		player_sprite.animation,
		player_sprite.frame
	)
	if frame_texture == null:
		return 61.0
	return float(frame_texture.get_height()) * absf(player_sprite.scale.y)


func _remove_upgrade_cost_coins() -> void:
	if not is_instance_valid(upgrade_coin_display):
		return
	upgrade_coin_display.queue_free()
	upgrade_coin_display = null


func _remove_e_prompt() -> void:
	_remove_upgrade_cost_coins()
	if not is_instance_valid(e_prompt):
		return
	e_prompt.queue_free()
	e_prompt = null
