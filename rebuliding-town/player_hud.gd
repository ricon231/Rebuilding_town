extends CanvasLayer

signal day_three_requested

@onready var day_three_button: Button = %DayThreeButton
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_value: Label = %HealthValue
@onready var coin_count: Label = %CoinCount
@onready var day_label: Label = %DayLabel
@onready var artifact_slot_icons: Array[TextureRect] = [
	%ArtifactSlot1Icon,
	%ArtifactSlot2Icon,
]
@onready var message_label: Label = %MessageLabel
@onready var message_panel: PanelContainer = $MessagePanel
@onready var town_status_label: Label = %TownStatusLabel

var player: Node
var day_label_tween: Tween
var message_tween: Tween


func _ready() -> void:
	day_three_button.pressed.connect(_on_day_three_button_pressed)
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if player.has_signal("health_changed"):
		player.connect("health_changed", _on_health_changed)
	if player.has_signal("coins_changed"):
		player.connect("coins_changed", _on_coins_changed)
	if player.has_signal("artifact_inventory_changed"):
		player.connect(
			"artifact_inventory_changed",
			_on_artifact_inventory_changed
		)

	_on_health_changed(
		int(player.get("health")),
		int(player.get("max_health"))
	)
	_on_coins_changed(int(player.get("coins")))
	_on_artifact_inventory_changed(player.get("artifact_slots"))


func _on_day_three_button_pressed() -> void:
	day_three_requested.emit()


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	health_bar.max_value = maxi(maximum_health, 1)
	health_bar.value = clampi(current_health, 0, maximum_health)
	health_value.text = "체력 %d / %d" % [current_health, maximum_health]


func _on_coins_changed(current_coins: int) -> void:
	coin_count.text = "엽전 %d" % current_coins


func show_current_day(current_day: int) -> void:
	if day_label_tween != null and day_label_tween.is_valid():
		day_label_tween.kill()

	day_label.text = "%d 일차" % current_day
	day_label.modulate.a = 1.0
	day_label.visible = true

	day_label_tween = create_tween()
	day_label_tween.tween_interval(3.0)
	day_label_tween.tween_property(day_label, "modulate:a", 0.0, 1.0)
	day_label_tween.tween_callback(day_label.hide)


func show_message(message: String) -> void:
	if not is_instance_valid(message_panel) or not is_instance_valid(message_label):
		return
	if message_tween != null and message_tween.is_valid():
		message_tween.kill()

	message_label.text = message
	message_panel.modulate.a = 1.0
	message_panel.visible = true
	message_tween = create_tween()
	message_tween.tween_interval(3.0)
	message_tween.tween_property(message_panel, "modulate:a", 0.0, 0.6)
	message_tween.tween_callback(message_panel.hide)


func show_town_status(status: Dictionary) -> String:
	var status_text := (
		"마을 운영\n"
		+ "주민  %d / %d명\n" % [
			int(status.get("citizens", 0)),
			int(status.get("capacity", 0)),
		]
		+ "광산  %d단계 · 하루 +%d\n" % [
			int(status.get("mine_stage", 0)),
			int(status.get("mine_income", 0)),
		]
		+ "대장간  %d단계 · 공격 +%d%%\n" % [
			int(status.get("blacksmith_stage", 0)),
			int(status.get("attack_bonus", 0)),
		]
		+ "관아  %d단계 · 수용 %d명\n" % [
			int(status.get("gwana_stage", 0)),
			int(status.get("capacity", 0)),
		]
		+ "복원소  %d단계\n" % int(status.get("restoration_stage", 0))
		+ "예상 일일 수입  %d엽전\n" % int(status.get("daily_income", 0))
		+ "승리 목표  유물 %d/%d · 관아 %d/%d단계" % [
			int(status.get("artifact_count", 0)),
			int(status.get("artifact_total", 0)),
			int(status.get("gwana_stage", 0)),
			int(status.get("victory_gwana_stage", 4)),
		]
	)
	town_status_label.text = status_text
	return status_text


func _on_artifact_inventory_changed(slots: Array) -> void:
	for slot_index in artifact_slot_icons.size():
		var artifact_id := &""
		if slot_index < slots.size():
			artifact_id = slots[slot_index]

		var texture_path := ArtifactCatalog.get_damaged_texture_path(artifact_id)
		artifact_slot_icons[slot_index].texture = (
			load(texture_path) as Texture2D
			if not texture_path.is_empty()
			else null
		)
