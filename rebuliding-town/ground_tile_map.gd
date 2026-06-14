extends TileMapLayer

const TILE_SIZE := Vector2(64.0, 64.0)
const COLLISION_ROOT_NAME := "GeneratedTileCollisions"


func _ready() -> void:
	rebuild_tile_collisions()


func rebuild_tile_collisions() -> void:
	var previous_root := get_node_or_null(COLLISION_ROOT_NAME)
	if previous_root != null:
		previous_root.queue_free()

	var collision_root := StaticBody2D.new()
	collision_root.name = COLLISION_ROOT_NAME
	collision_root.collision_layer = 1
	collision_root.collision_mask = 0
	add_child(collision_root)

	for cell in get_used_cells():
		var collision_shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = TILE_SIZE
		collision_shape.shape = rectangle
		collision_shape.position = map_to_local(cell)
		collision_root.add_child(collision_shape)
