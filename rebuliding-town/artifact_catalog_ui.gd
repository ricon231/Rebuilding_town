extends CanvasLayer

const LOCKED_TEXT := "아직 발견하지 못한 유물입니다."

@onready var item_list: VBoxContainer = %ItemList
@onready var artifact_name: Label = %ArtifactName
@onready var artifact_effect: RichTextLabel = %ArtifactEffect
@onready var artifact_image: TextureRect = %ArtifactImage
@onready var artifact_description: RichTextLabel = %ArtifactDescription
@onready var counter_label: Label = %CounterLabel
@onready var close_button: Button = %CloseButton

var selected_id: StringName
var grayscale_material: ShaderMaterial
var normal_icons: Dictionary = {}
var grayscale_icons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	grayscale_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c = texture(TEXTURE, UV); float g = dot(c.rgb, vec3(0.299, 0.587, 0.114)); COLOR = vec4(vec3(g) * 0.45, c.a); }"
	grayscale_material.shader = shader
	close_button.pressed.connect(close_catalog)
	ArtifactCatalog.artifact_registered.connect(_on_artifact_registered)
	_rebuild_list()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			if visible:
				close_catalog()
			else:
				open_catalog()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and visible:
			close_catalog()
			get_viewport().set_input_as_handled()


func open_catalog() -> void:
	if get_tree().paused and not visible:
		return
	visible = true
	get_tree().paused = true
	_rebuild_list()
	if selected_id == &"" and not ArtifactCatalog.ARTIFACTS.is_empty():
		_select_artifact(ArtifactCatalog.ARTIFACTS[0].id)
	close_button.grab_focus()


func close_catalog() -> void:
	visible = false
	get_tree().paused = false


func _rebuild_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var found := 0
	for artifact in ArtifactCatalog.ARTIFACTS:
		var unlocked := ArtifactCatalog.is_registered(artifact.id)
		if unlocked:
			found += 1
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 58)
		button.text = artifact.name if unlocked else "미등록 유물"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var texture: Texture2D = load(artifact.texture)
		button.icon = _get_normal_icon(artifact.id, texture) if unlocked else _get_grayscale_icon(artifact.id, texture)
		button.expand_icon = true
		button.tooltip_text = artifact.name if unlocked else LOCKED_TEXT
		button.pressed.connect(_select_artifact.bind(artifact.id))
		item_list.add_child(button)

	counter_label.text = "%d / %d 등록" % [found, ArtifactCatalog.ARTIFACTS.size()]


func _select_artifact(artifact_id: StringName) -> void:
	selected_id = artifact_id
	var artifact := ArtifactCatalog.get_artifact(artifact_id)
	var unlocked := ArtifactCatalog.is_registered(artifact_id)
	artifact_image.texture = load(artifact.texture)
	artifact_image.material = null if unlocked else grayscale_material
	artifact_effect.text = (
		ArtifactCatalog.get_effect_bbcode(artifact_id)
		if unlocked
		else "[color=#777b84]해금 후 효과를 확인할 수 있습니다.[/color]"
	)
	artifact_name.text = artifact.name if unlocked else "미등록 유물"
	artifact_description.text = ArtifactCatalog.get_description(artifact_id) if unlocked else LOCKED_TEXT


func _on_artifact_registered(artifact_id: StringName) -> void:
	selected_id = artifact_id
	_rebuild_list()
	_select_artifact(artifact_id)


func _get_normal_icon(artifact_id: StringName, texture: Texture2D) -> Texture2D:
	if normal_icons.has(artifact_id):
		return normal_icons[artifact_id]

	var image := texture.get_image()
	image.resize(44, 44, Image.INTERPOLATE_NEAREST)
	var icon_texture := ImageTexture.create_from_image(image)
	normal_icons[artifact_id] = icon_texture
	return icon_texture


func _get_grayscale_icon(artifact_id: StringName, texture: Texture2D) -> Texture2D:
	if grayscale_icons.has(artifact_id):
		return grayscale_icons[artifact_id]

	var image := texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(44, 44, Image.INTERPOLATE_NEAREST)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var gray := (color.r * 0.299 + color.g * 0.587 + color.b * 0.114) * 0.45
			image.set_pixel(x, y, Color(gray, gray, gray, color.a))

	var gray_texture := ImageTexture.create_from_image(image)
	grayscale_icons[artifact_id] = gray_texture
	return gray_texture
