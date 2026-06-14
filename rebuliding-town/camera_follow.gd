extends Camera2D

@export var target_path: NodePath
@export var camera_zoom := Vector2(3.6, 3.6)
@export var follow_smoothing := 10.0
@export var follow_offset := Vector2(0.0, -100.0)

var target: Node2D


func _ready() -> void:
	zoom = camera_zoom
	top_level = true
	make_current()

	if target_path != NodePath():
		target = get_node_or_null(target_path) as Node2D
	else:
		target = get_parent() as Node2D

	if target != null:
		global_position = target.global_position + follow_offset


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var weight := 1.0 - exp(-follow_smoothing * delta)
	var target_position := target.global_position + follow_offset
	global_position = global_position.lerp(target_position, weight)
