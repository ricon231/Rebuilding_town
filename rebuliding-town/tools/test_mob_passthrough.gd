extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main_scene := load("res://main.tscn") as PackedScene
	var game := main_scene.instantiate()
	root.add_child(game)
	await process_frame

	var bear := (
		load("res://bear.tscn") as PackedScene
	).instantiate() as CharacterBody2D
	var deer := (
		load("res://deer.tscn") as PackedScene
	).instantiate() as CharacterBody2D
	game.get_node("Animals/Hostile").add_child(bear)
	game.get_node("Animals/Passive").add_child(deer)
	await process_frame
	await process_frame

	var player := game.get_node("Player") as CharacterBody2D
	assert(bear.collision_layer == 4 and bear.collision_mask == 1)
	assert(deer.collision_layer == 4 and deer.collision_mask == 1)
	assert(player.collision_layer == 2 and player.collision_mask == 1)
	assert(bear.get_collision_exceptions().is_empty())
	assert(deer.get_collision_exceptions().is_empty())
	print("Mob collision layer test passed.")
	quit()
