extends Node

signal day_completed

const SUN_TEXTURE := preload("res://assets/sun_pixel.png")
const MOON_TEXTURE := preload("res://assets/moon_pixel.png")

@export var day_length_seconds := 180.0
@export_range(0.0, 1.0, 0.01) var starting_time_progress := 0.85
@export var sky_color := Color(0.45, 0.75, 1.0)
@export var sunset_color := Color(1.0, 0.45, 0.22)
@export var night_color := Color(0.03, 0.05, 0.14)
@export_range(0.0, 1.0, 0.01) var max_night_filter_alpha := 0.48
@export var celestial_y := 110.0
@export var celestial_side_margin := 96.0
@export var celestial_arc_height := 48.0

var time_elapsed := 0.0
var background_rect: ColorRect
var night_filter_rect: ColorRect
var sun_sprite: Sprite2D
var moon_sprite: Sprite2D
var time_locked := false


func is_daytime() -> bool:
	if day_length_seconds <= 0.0:
		return false
	return time_elapsed / day_length_seconds < 0.7


func _ready() -> void:
	time_elapsed = day_length_seconds * starting_time_progress
	_create_background()
	_create_celestial_sprites()
	_create_night_filter()
	_update_time_of_day()


func _process(delta: float) -> void:
	if day_length_seconds <= 0.0 or time_locked:
		return

	time_elapsed += delta
	while time_elapsed >= day_length_seconds:
		time_elapsed -= day_length_seconds
		day_completed.emit()
	_update_time_of_day()


func lock_to_night() -> void:
	time_locked = true
	time_elapsed = day_length_seconds * 0.85
	_update_time_of_day()


func is_time_locked() -> bool:
	return time_locked


func get_save_data() -> Dictionary:
	return {
		"time_elapsed": time_elapsed,
		"time_locked": time_locked,
	}


func apply_save_data(data: Dictionary) -> void:
	time_elapsed = clampf(
		float(data.get("time_elapsed", time_elapsed)),
		0.0,
		maxf(day_length_seconds, 0.0)
	)
	time_locked = bool(data.get("time_locked", false))
	_update_time_of_day()


func _create_background() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.name = "SkyBackgroundLayer"
	background_layer.layer = -100
	add_child(background_layer)

	background_rect = ColorRect.new()
	background_rect.name = "SkyBackground"
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(background_rect)


func _create_celestial_sprites() -> void:
	var celestial_layer := CanvasLayer.new()
	celestial_layer.name = "CelestialLayer"
	celestial_layer.layer = -90
	add_child(celestial_layer)

	sun_sprite = Sprite2D.new()
	sun_sprite.name = "Sun"
	sun_sprite.texture = SUN_TEXTURE
	sun_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sun_sprite.scale = Vector2(0.075, 0.075)
	celestial_layer.add_child(sun_sprite)

	moon_sprite = Sprite2D.new()
	moon_sprite.name = "Moon"
	moon_sprite.texture = MOON_TEXTURE
	moon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	moon_sprite.scale = Vector2(1.5, 1.5)
	celestial_layer.add_child(moon_sprite)


func _create_night_filter() -> void:
	var filter_layer := CanvasLayer.new()
	filter_layer.name = "NightFilterLayer"
	filter_layer.layer = 100
	add_child(filter_layer)

	night_filter_rect = ColorRect.new()
	night_filter_rect.name = "NightFilter"
	night_filter_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	night_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filter_layer.add_child(night_filter_rect)


func _update_time_of_day() -> void:
	var progress := time_elapsed / day_length_seconds
	background_rect.color = _get_background_color(progress)
	night_filter_rect.color = Color(0.0, 0.0, 0.06, _get_night_alpha(progress))
	get_tree().call_group("day_night_background", "set_day_night_tint", _get_landscape_tint(progress))
	get_tree().call_group_flags(
		SceneTree.GROUP_CALL_DEFERRED,
		"day_night_reactive",
		"set_day_night_progress",
		progress
	)
	_update_celestial_sprites(progress)


func _update_celestial_sprites(progress: float) -> void:
	if progress < 0.7:
		var sun_progress := inverse_lerp(0.0, 0.7, progress)
		sun_sprite.visible = true
		moon_sprite.visible = false
		sun_sprite.position = _get_celestial_position(sun_progress)
		sun_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		var moon_progress := inverse_lerp(0.7, 1.0, progress)
		sun_sprite.visible = false
		moon_sprite.visible = true
		moon_sprite.position = _get_celestial_position(moon_progress)
		moon_sprite.modulate = Color(1.0, 1.0, 1.0, 0.9)


func _get_celestial_position(progress: float) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var x: float = lerpf(-celestial_side_margin, viewport_size.x + celestial_side_margin, progress)
	var arc: float = sin(progress * PI) * celestial_arc_height
	return Vector2(x, celestial_y - arc)


func _get_background_color(progress: float) -> Color:
	if progress < 0.5:
		return sky_color
	if progress < 0.7:
		return sky_color.lerp(sunset_color, inverse_lerp(0.5, 0.7, progress))
	if progress < 0.85:
		return sunset_color.lerp(night_color, inverse_lerp(0.7, 0.85, progress))
	return night_color.lerp(sky_color, inverse_lerp(0.85, 1.0, progress))


func _get_night_alpha(progress: float) -> float:
	if progress < 0.7:
		return 0.0
	if progress < 0.85:
		return lerpf(0.0, max_night_filter_alpha, inverse_lerp(0.7, 0.85, progress))
	return lerpf(max_night_filter_alpha, 0.0, inverse_lerp(0.85, 1.0, progress))


func _get_landscape_tint(progress: float) -> Color:
	var daylight := Color.WHITE
	var sunset := Color(1.0, 0.72, 0.58)
	var night := Color(0.42, 0.48, 0.66)

	if progress < 0.5:
		return daylight
	if progress < 0.7:
		return daylight.lerp(sunset, inverse_lerp(0.5, 0.7, progress))
	if progress < 0.85:
		return sunset.lerp(night, inverse_lerp(0.7, 0.85, progress))
	return night.lerp(daylight, inverse_lerp(0.85, 1.0, progress))
