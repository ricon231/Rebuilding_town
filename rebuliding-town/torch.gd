extends Node2D

@export_range(0.0, 1.0, 0.01) var night_start := 0.7
@export_range(0.0, 1.0, 0.01) var morning_start := 0.92
@export_range(0.0, 4.0, 0.05) var light_energy := 1.15
@export_range(0.0, 0.2, 0.001) var flicker_amount := 0.035
@export_range(0.1, 20.0, 0.1) var flicker_speed := 7.0

var lit_sprite: Sprite2D
var unlit_sprite: Sprite2D
var torch_light: PointLight2D

var is_lit := false
var flicker_time := 0.0


func _ready() -> void:
	add_to_group("day_night_reactive")
	_resolve_nodes()
	_set_lit(false)

	var cycle := get_tree().get_first_node_in_group("day_night_cycle")
	if cycle != null and cycle.get("day_length_seconds") > 0.0:
		set_day_night_progress(
			float(cycle.get("time_elapsed"))
			/ float(cycle.get("day_length_seconds"))
		)


func _process(delta: float) -> void:
	if not is_lit or not is_instance_valid(torch_light):
		return

	flicker_time += delta * flicker_speed
	var flicker := sin(flicker_time) * flicker_amount
	flicker += sin(flicker_time * 2.37) * flicker_amount * 0.45
	torch_light.energy = maxf(light_energy + flicker, 0.0)


func set_day_night_progress(progress: float) -> void:
	_set_lit(progress >= night_start and progress < morning_start)


func _set_lit(value: bool) -> void:
	is_lit = value
	_resolve_nodes()
	if (
		not is_instance_valid(lit_sprite)
		or not is_instance_valid(unlit_sprite)
		or not is_instance_valid(torch_light)
	):
		return

	lit_sprite.visible = value
	unlit_sprite.visible = not value
	torch_light.enabled = value
	if value:
		torch_light.energy = light_energy


func _resolve_nodes() -> void:
	if not is_instance_valid(lit_sprite):
		lit_sprite = get_node_or_null("LitSprite") as Sprite2D
	if not is_instance_valid(unlit_sprite):
		unlit_sprite = get_node_or_null("UnlitSprite") as Sprite2D
	if not is_instance_valid(torch_light):
		torch_light = get_node_or_null("TorchLight") as PointLight2D
