extends CanvasLayer

@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var quit_button: Button = %QuitButton
@onready var status_label: Label = %StatusLabel
@onready var town_status_label: Label = %TownStatusLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	resume_button.pressed.connect(_resume_game)
	save_button.pressed.connect(_save_game)
	load_button.pressed.connect(_load_game)
	quit_button.pressed.connect(_quit_game)
	_refresh_load_button()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var game_over_ui := get_tree().get_first_node_in_group("game_over_ui")
		if is_instance_valid(game_over_ui) and game_over_ui.visible:
			return
		var catalog := get_tree().get_first_node_in_group("artifact_catalog_ui")
		if is_instance_valid(catalog) and catalog.visible:
			return
		if visible:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()


func _pause_game() -> void:
	visible = true
	get_tree().paused = true
	status_label.text = ""
	_refresh_load_button()
	resume_button.grab_focus()


func _resume_game() -> void:
	visible = false
	get_tree().paused = false


func _save_game() -> void:
	var main := get_tree().current_scene
	var saved := (
		main != null
		and main.has_method("save_game")
		and bool(main.call("save_game"))
	)
	status_label.text = (
		"게임을 저장했습니다."
		if saved
		else "게임 저장에 실패했습니다."
	)
	_refresh_load_button()


func _load_game() -> void:
	var main := get_tree().current_scene
	var loaded := (
		main != null
		and main.has_method("load_game")
		and bool(main.call("load_game"))
	)
	status_label.text = (
		"저장된 게임을 불러왔습니다."
		if loaded
		else "불러올 저장 파일이 없습니다."
	)
	if loaded:
		_resume_game()


func _refresh_load_button() -> void:
	var main := get_tree().current_scene
	load_button.disabled = not (
		main != null
		and main.has_method("has_save_file")
		and bool(main.call("has_save_file"))
	)


func show_town_status(status_text: String) -> void:
	town_status_label.text = status_text


func _quit_game() -> void:
	get_tree().quit()
