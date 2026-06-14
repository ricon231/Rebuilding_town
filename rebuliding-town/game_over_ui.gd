extends CanvasLayer

@onready var building_score_label: Label = %BuildingScore
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var citizen_score_label: Label = %CitizenScore
@onready var coin_score_label: Label = %CoinScore
@onready var artifact_score_label: Label = %ArtifactScore
@onready var day_score_label: Label = %DayScore
@onready var total_score_label: Label = %TotalScore
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	restart_button.pressed.connect(_restart_game)
	quit_button.pressed.connect(_quit_game)


func show_results(results: Dictionary, victory := false) -> void:
	if victory:
		title_label.text = "마을 재건 완료"
		title_label.add_theme_color_override(
			"font_color",
			Color(0.95, 0.75, 0.22, 1.0)
		)
		subtitle_label.text = "모든 유물을 복원하고 중심 관아를 완성했습니다."
	else:
		title_label.text = "게임 오버"
		title_label.add_theme_color_override(
			"font_color",
			Color(0.94, 0.24, 0.18, 1.0)
		)
		subtitle_label.text = "마을 재건 기록"

	building_score_label.text = "건물 업그레이드 %d회  × 100 = %d점" % [
		int(results.building_count),
		int(results.building_score),
	]
	citizen_score_label.text = "사람 %d명  × 8 = %d점" % [
		int(results.citizen_count),
		int(results.citizen_score),
	]
	coin_score_label.text = "보유 엽전 %d개  × 1 = %d점" % [
		int(results.coin_count),
		int(results.coin_score),
	]
	artifact_score_label.text = "복원 유물 %d개  × 5 = %d점" % [
		int(results.artifact_count),
		int(results.artifact_score),
	]
	day_score_label.text = "생존 날짜 %d일  × 10 = %d점" % [
		int(results.day_count),
		int(results.day_score),
	]
	total_score_label.text = "총점  %d점" % int(results.total_score)
	visible = true
	get_tree().paused = true
	restart_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _quit_game() -> void:
	get_tree().quit()
