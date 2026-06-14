extends "res://upgrade_building.gd"

const RESTORATION_COSTS := [5, 3, 1]
const RESTORATION_DURATIONS := [7.0, 5.0, 3.0]

var restoration_progress: ProgressBar

var restoring := false
var restoring_artifact_id: StringName
var restoration_tween: Tween


func _ready() -> void:
	super()
	restoration_progress = get_node_or_null("RestorationProgress") as ProgressBar
	if restoration_progress == null:
		restoration_progress = _create_restoration_progress()
	_position_restoration_progress()
	restoration_progress.visible = false
	restoration_progress.value = 0.0


func _unhandled_key_input(event: InputEvent) -> void:
	super(event)
	if not (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		return
	if restoring or not player_in_range:
		return

	var slot_index := -1
	if event.physical_keycode == KEY_1 or event.keycode == KEY_1:
		slot_index = 0
	elif event.physical_keycode == KEY_2 or event.keycode == KEY_2:
		slot_index = 1

	if slot_index >= 0:
		_try_start_restoration(slot_index)
		get_viewport().set_input_as_handled()


func _update_building() -> void:
	super()
	_position_restoration_progress()


func _try_start_restoration(slot_index: int) -> void:
	if not is_instance_valid(interacting_player):
		return
	if not interacting_player.has_method("get_artifact_in_slot"):
		return

	var artifact_id: StringName = interacting_player.call(
		"get_artifact_in_slot",
		slot_index
	)
	if artifact_id == &"":
		_show_hud_message("%d번 아이템 칸이 비어 있습니다." % (slot_index + 1))
		return

	var stage_index := clampi(
		current_stage,
		0,
		RESTORATION_COSTS.size() - 1
	)
	var restoration_cost: int = RESTORATION_COSTS[stage_index]
	if not bool(interacting_player.call("spend_coins", restoration_cost)):
		_show_hud_message("유물 복원 비용이 부족합니다.")
		return

	restoring_artifact_id = interacting_player.call(
		"remove_artifact_from_slot",
		slot_index
	)
	var restoration_duration: float = RESTORATION_DURATIONS[stage_index]
	if ArtifactCatalog.has_effect(&"octagonal_brush_holder"):
		restoration_duration *= 0.8
	_start_restoration(restoration_duration)


func _start_restoration(duration: float) -> void:
	restoring = true
	upgrading = true
	_remove_e_prompt()
	restoration_progress.value = 0.0
	restoration_progress.visible = true

	if restoration_tween != null and restoration_tween.is_valid():
		restoration_tween.kill()
	restoration_tween = create_tween()
	restoration_tween.tween_property(
		restoration_progress,
		"value",
		100.0,
		duration
	)
	restoration_tween.tween_callback(_complete_restoration)


func _complete_restoration() -> void:
	ArtifactCatalog.register_artifact(restoring_artifact_id)
	var artifact_name := ArtifactCatalog.get_artifact_name(
		restoring_artifact_id
	)
	_show_hud_message("%s이 복원되었습니다!" % artifact_name)

	restoring_artifact_id = &""
	restoring = false
	upgrading = false
	restoration_progress.visible = false
	restoration_progress.value = 0.0
	if player_in_range and not _is_maximum_stage():
		_create_e_prompt()


func _show_hud_message(message: String) -> void:
	var hud := get_tree().get_first_node_in_group("player_hud")
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", message)


func _create_restoration_progress() -> ProgressBar:
	var progress := ProgressBar.new()
	progress.name = "RestorationProgress"
	progress.size = Vector2(144.0, 16.0)
	progress.z_index = 4095
	progress.z_as_relative = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.show_percentage = false

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.22, 0.23, 0.25, 0.96)
	background.border_width_left = 2
	background.border_width_top = 2
	background.border_width_right = 2
	background.border_width_bottom = 2
	background.border_color = Color(0.08, 0.08, 0.09, 1.0)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.16, 0.72, 0.25, 1.0)
	progress.add_theme_stylebox_override("background", background)
	progress.add_theme_stylebox_override("fill", fill)
	add_child(progress)
	return progress


func _position_restoration_progress() -> void:
	if not is_instance_valid(restoration_progress) or stage_sprites.is_empty():
		return

	var current_sprite := stage_sprites[current_stage] as Sprite2D
	if current_sprite == null:
		return

	var building_size := _get_sprite_display_size(current_sprite)
	var building_bottom := current_sprite.position.y + building_size.y * 0.5
	restoration_progress.position = Vector2(
		current_sprite.position.x - restoration_progress.size.x * 0.5,
		building_bottom + 6.0
	)
