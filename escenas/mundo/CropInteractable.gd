extends Area3D

@export var crop_name: String = ""
@export var crop_subtitle: String = ""
@export var crop_description: String = ""
@export var crop_history: String = ""
@export var crop_region: String = ""
@export var crop_icon_path: String = ""

@onready var mesh_node: MeshInstance3D = $"../MeshInstance3D"
@onready var outline_material: ShaderMaterial = preload("res://materials/crop_outline.tres").duplicate()

var original_material: Material = null
var is_hovered: bool = false
var _tween: Tween

func _ready() -> void:
	if mesh_node:
		original_material = mesh_node.get_surface_override_material(0)
	monitoring = true
	monitorable = true
	input_ray_pickable = true
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	input_event.connect(_on_input_event)


func _on_hover_enter() -> void:
	is_hovered = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if mesh_node:
		mesh_node.set_surface_override_material(0, outline_material)
	_tween.tween_method(
		func(v: float) -> void: outline_material.set_shader_parameter("outline_width", v),
		0.0, 0.025, 0.2
	)
	var ui := _get_ui()
	if ui:
		ui.show_crop_tooltip(crop_name, global_position)


func _on_hover_exit() -> void:
	is_hovered = false
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(
		func(v: float) -> void: outline_material.set_shader_parameter("outline_width", v),
		0.025, 0.0, 0.15
	)
	_tween.tween_callback(func() -> void:
		if mesh_node:
			mesh_node.set_surface_override_material(0, original_material)
	)
	var ui := _get_ui()
	if ui:
		ui.hide_crop_tooltip()


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		abrir_modal_desde_jugador()


func abrir_modal_desde_jugador() -> void:
	var ui := _get_ui()
	if ui:
		ui.show_crop_modal(
			crop_name,
			crop_subtitle,
			crop_description,
			crop_history,
			crop_region,
			crop_icon_path
		)


func _get_ui() -> Node:
	var escena := get_tree().current_scene
	if escena:
		var ui_escena := escena.get_node_or_null("GameUI")
		if ui_escena:
			return ui_escena
	return get_tree().root.find_child("GameUI", true, false)
