extends CanvasLayer

@export var player_path: NodePath
@export_range(0.0, 1.0, 0.01) var horizontal_strength := 0.18
@export_range(0.0, 0.2, 0.01) var vertical_strength := 0.02

@onready var panorama: Sprite2D = $Panorama

var player: Node2D
var starting_player_position := Vector2.ZERO
var base_position := Vector2.ZERO


func _ready() -> void:
	player = get_node_or_null(player_path) as Node2D
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()

	if player != null:
		starting_player_position = player.global_position


func _process(_delta: float) -> void:
	if player == null:
		return

	var player_offset := player.global_position - starting_player_position
	var viewport_size := get_viewport().get_visible_rect().size
	var scaled_width := panorama.texture.get_width() * panorama.scale.x
	var minimum_x := minf(0.0, viewport_size.x - scaled_width)
	var target_x := base_position.x - player_offset.x * horizontal_strength

	panorama.position.x = clampf(target_x, minimum_x, 0.0)
	panorama.position.y = base_position.y - player_offset.y * vertical_strength


func set_day_night_tint(tint: Color) -> void:
	panorama.modulate = tint


func _fit_to_viewport() -> void:
	if panorama.texture == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var texture_size := panorama.texture.get_size()
	var scale_factor := viewport_size.y / texture_size.y
	panorama.scale = Vector2.ONE * scale_factor
	base_position = Vector2.ZERO
	panorama.position = base_position
