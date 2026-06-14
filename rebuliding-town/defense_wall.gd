extends Node2D

@export var left_building_path: NodePath
@export var right_building_path: NodePath

@onready var stage_sprites: Array[Node] = $Stages.get_children()

var left_building: Node
var right_building: Node


func _ready() -> void:
	left_building = get_node_or_null(left_building_path)
	right_building = get_node_or_null(right_building_path)
	_connect_building(left_building)
	_connect_building(right_building)
	_update_wall()


func _connect_building(building: Node) -> void:
	if building != null and building.has_signal("upgraded"):
		building.connect(&"upgraded", _on_building_upgraded)


func _on_building_upgraded(_new_stage: int) -> void:
	_update_wall()


func _update_wall() -> void:
	var wall_stage := mini(
		_get_building_stage(left_building),
		_get_building_stage(right_building)
	)

	for stage_index in stage_sprites.size():
		stage_sprites[stage_index].visible = (
			wall_stage > 0
			and stage_index == mini(wall_stage, stage_sprites.size()) - 1
		)


func _get_building_stage(building: Node) -> int:
	if building == null:
		return 0
	return maxi(int(building.get("current_stage")), 0)
