extends Node

signal artifact_registered(artifact_id: StringName)

const SAVE_PATH := "user://artifact_catalog.json"

const ARTIFACT_DISPLAY_NAMES := {
	&"phoenix_pillow": "봉황 자수 베갯모",
	&"phoenix_vase": "청화백자 봉황무늬 항아리",
	&"phoenix_paintings": "봉황 그림",
	&"octagonal_brush_holder": "팔각 칠기 붓통",
	&"deer_lunch_box": "사슴무늬 칠기 상자",
	&"zodiac_sundial": "십이지 해시계",
	&"round_textile": "봉황무늬 원형 직물",
	&"longevity_pouch": "봉황 자수 주머니",
	&"guardian_tile": "귀면 기와",
	&"mother_of_pearl_brush_stand": "나전칠기 붓통",
}

const DAMAGED_TEXTURES := {
	&"phoenix_pillow": "res://assets/items_museum/embroidered_phoenix_pillow_end_256_damaged.png",
	&"phoenix_vase": "res://assets/items_museum/blue_white_phoenix_vase_item_256_damaged.png",
	&"phoenix_paintings": "res://assets/items_museum/painting_sun_pine_phoenix_pair_256_damaged.png",
	&"octagonal_brush_holder": "res://assets/items_museum/octagonal_lacquer_brush_holder_256_damaged.png",
	&"deer_lunch_box": "res://assets/items_museum/lacquer_deer_pine_crane_box_256_damaged.png",
	&"zodiac_sundial": "res://assets/items_museum/blue_white_zodiac_sundial_256_damaged.png",
	&"round_textile": "res://assets/items_museum/large_gold_mythical_textile_256_damaged.png",
	&"longevity_pouch": "res://assets/items_museum/red_phoenix_embroidered_pouch_256_damaged.png",
	&"guardian_tile": "res://assets/items_museum/gray_fanged_guardian_tile_256_damaged.png",
	&"mother_of_pearl_brush_stand": "res://assets/items_museum/mother_of_pearl_hexagonal_brush_stand_256_damaged.png",
}

const EFFECT_COLOR_HEALTH := "62d97b"
const EFFECT_COLOR_ATTACK := "f06464"
const EFFECT_COLOR_SPEED := "66c9f2"
const EFFECT_COLOR_OTHER := "f2d35f"

const ARTIFACT_EFFECTS := {
	&"phoenix_pillow": [
		{"text": "최대 체력 +50", "color": EFFECT_COLOR_HEALTH},
		{"text": "체력 회복량 +1", "color": EFFECT_COLOR_HEALTH},
	],
	&"phoenix_vase": [
		{"text": "최대 체력 +25", "color": EFFECT_COLOR_HEALTH},
		{"text": "체력 회복량 +3", "color": EFFECT_COLOR_HEALTH},
	],
	&"phoenix_paintings": [
		{"text": "밤에도 체력 회복 가능", "color": EFFECT_COLOR_HEALTH},
	],
	&"octagonal_brush_holder": [
		{"text": "유물 복원 시간 -20%", "color": EFFECT_COLOR_OTHER},
	],
	&"deer_lunch_box": [
		{"text": "유물 획득 확률 +20%", "color": EFFECT_COLOR_OTHER},
	],
	&"zodiac_sundial": [
		{"text": "공격력 +20%", "color": EFFECT_COLOR_ATTACK},
		{"text": "최대 체력 +10", "color": EFFECT_COLOR_HEALTH},
		{"text": "이동 속도 +20%", "color": EFFECT_COLOR_SPEED},
	],
	&"round_textile": [
		{"text": "체력 회복량 +5", "color": EFFECT_COLOR_HEALTH},
	],
	&"longevity_pouch": [
		{"text": "체력이 30% 아래로 떨어지면 3초 무적 (매일 1회)", "color": EFFECT_COLOR_HEALTH},
	],
	&"guardian_tile": [
		{"text": "공격력 +60%", "color": EFFECT_COLOR_ATTACK},
	],
	&"mother_of_pearl_brush_stand": [
		{"text": "5초마다 1원 획득", "color": EFFECT_COLOR_OTHER},
	],
}

const ARTIFACTS := [
	{
		"id": &"phoenix_pillow",
		"name": "봉황을 수놓은 베갯모와 자수 봉황도",
		"texture": "res://assets/items_museum/embroidered_phoenix_pillow_end_256.png",
		"text": "res://artifacts/museum_text/transcripts/봉황을 수놓은 베갯모와 자수 봉황도(수정본).txt",
	},
	{
		"id": &"phoenix_vase",
		"name": "자수 봉황도와 청화백자 봉황문 항아리",
		"texture": "res://assets/items_museum/blue_white_phoenix_vase_item_256.png",
		"text": "res://artifacts/museum_text/transcripts/자수 봉황도와 청화백자 봉황문 항아리(수정본).txt",
	},
	{
		"id": &"phoenix_paintings",
		"name": "봉황 그림 두 점",
		"texture": "res://assets/items_museum/painting_sun_pine_phoenix_pair_256.png",
		"text": "res://artifacts/museum_text/transcripts/봉황 그림 두 점(수정본).txt",
	},
	{
		"id": &"octagonal_brush_holder",
		"name": "꽃과 새·동물을 새긴 팔각 필통",
		"texture": "res://assets/items_museum/octagonal_lacquer_brush_holder_256.png",
		"text": "res://artifacts/museum_text/transcripts/꽃과 새·동물을 새긴 팔각 필통(수정본).txt",
	},
	{
		"id": &"deer_lunch_box",
		"name": "사슴·소나무·박쥐를 새긴 도시락통",
		"texture": "res://assets/items_museum/lacquer_deer_pine_crane_box_256.png",
		"text": "res://artifacts/museum_text/transcripts/사슴·소나무·박쥐를 새긴 도시락통(수정본).txt",
	},
	{
		"id": &"zodiac_sundial",
		"name": "십이지 청화백자 해시계와 닭 그림",
		"texture": "res://assets/items_museum/blue_white_zodiac_sundial_256.png",
		"text": "res://artifacts/museum_text/transcripts/십이지 청화백자 해시계와 닭 그림(수정본).txt",
	},
	{
		"id": &"round_textile",
		"name": "원형 직물 장식과 용무늬 장식",
		"texture": "res://assets/items_museum/large_gold_mythical_textile_256.png",
		"text": "res://artifacts/museum_text/transcripts/원형 직물 장식과 용무늬 장식(수정본).txt",
	},
	{
		"id": &"longevity_pouch",
		"name": "십장생 귀주머니",
		"texture": "res://assets/items_museum/red_phoenix_embroidered_pouch_256.png",
		"text": "res://artifacts/museum_text/transcripts/십장생 귀주머니(수정본).txt",
	},
	{
		"id": &"guardian_tile",
		"name": "짐승얼굴무늬 기와",
		"texture": "res://assets/items_museum/gray_fanged_guardian_tile_256.png",
		"text": "res://artifacts/museum_text/transcripts/짐승얼굴무늬 기와(수정본).txt",
	},
	{
		"id": &"mother_of_pearl_brush_stand",
		"name": "나전필통과 대나무 필통",
		"texture": "res://assets/items_museum/mother_of_pearl_hexagonal_brush_stand_256.png",
		"text": "res://artifacts/museum_text/transcripts/나전필통과 대나무 필통(수정본).txt",
	},
]

var registered: Dictionary = {}


func _ready() -> void:
	registered.clear()


func register_artifact(artifact_id: StringName) -> bool:
	if registered.has(artifact_id):
		return false
	if get_artifact(artifact_id).is_empty():
		return false

	registered[artifact_id] = true
	save_catalog()
	artifact_registered.emit(artifact_id)
	return true


func is_registered(artifact_id: StringName) -> bool:
	return registered.has(artifact_id)


func get_artifact(artifact_id: StringName) -> Dictionary:
	for artifact in ARTIFACTS:
		if artifact.id == artifact_id:
			return artifact
	return {}


func get_artifact_name(artifact_id: StringName) -> String:
	return ARTIFACT_DISPLAY_NAMES.get(artifact_id, str(artifact_id))


func get_damaged_texture_path(artifact_id: StringName) -> String:
	return DAMAGED_TEXTURES.get(artifact_id, "")


func has_effect(artifact_id: StringName) -> bool:
	return is_registered(artifact_id)


func get_effect_bbcode(artifact_id: StringName) -> String:
	var lines: Array[String] = []
	for effect in ARTIFACT_EFFECTS.get(artifact_id, []):
		lines.append(
			"[color=#%s]• %s[/color]" % [
				String(effect.color),
				String(effect.text),
			]
		)
	return "\n".join(lines)


func get_description(artifact_id: StringName) -> String:
	var artifact := get_artifact(artifact_id)
	if artifact.is_empty():
		return ""
	var text_path := String(artifact.text)
	if not text_path.contains("(수정본)"):
		return "수정본 설명 파일이 연결되지 않았습니다."
	var file := FileAccess.open(text_path, FileAccess.READ)
	if file == null:
		return "수정본 설명 파일을 불러올 수 없습니다."
	return _extract_body_sections(file.get_as_text())


func save_catalog() -> void:
	var ids: Array[String] = []
	for artifact_id in registered:
		ids.append(str(artifact_id))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"registered": ids}))


func reset_catalog() -> void:
	registered.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func load_catalog() -> void:
	registered.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		for artifact_id in data.get("registered", []):
			registered[StringName(artifact_id)] = true


func get_registered_ids() -> Array[String]:
	var ids: Array[String] = []
	for artifact_id in registered:
		ids.append(str(artifact_id))
	return ids


func apply_registered_ids(ids: Array) -> void:
	registered.clear()
	for value in ids:
		var artifact_id := StringName(str(value))
		if not get_artifact(artifact_id).is_empty():
			registered[artifact_id] = true


func _extract_body_sections(text: String) -> String:
	var sections: Array[String] = []
	var current: Array[String] = []
	var reading_body := false

	for raw_line in text.split("\n"):
		var heading_line := raw_line.strip_edges()
		if heading_line == "[본문]":
			if not current.is_empty():
				sections.append("\n".join(current).strip_edges())
				current.clear()
			reading_body = true
			continue
		if heading_line.begins_with("[") and heading_line.ends_with("]"):
			if reading_body and not current.is_empty():
				sections.append("\n".join(current).strip_edges())
				current.clear()
			reading_body = false
			continue
		if reading_body:
			current.append(raw_line.trim_suffix("\r"))

	if reading_body and not current.is_empty():
		sections.append("\n".join(current).strip_edges())

	if sections.is_empty():
		var supplement := _extract_named_section(text, "[교정 및 보충 설명]")
		if not supplement.is_empty():
			return supplement
		return "사진에서 본문을 판독하지 못했습니다."
	return "\n\n".join(sections)


func _extract_named_section(text: String, heading: String) -> String:
	var lines: Array[String] = []
	var reading := false
	for raw_line in text.split("\n"):
		var heading_line := raw_line.strip_edges()
		if heading_line == heading:
			reading = true
			continue
		if reading and heading_line.begins_with("[") and heading_line.ends_with("]"):
			break
		if reading:
			lines.append(raw_line.trim_suffix("\r"))
	return "\n".join(lines).strip_edges()
