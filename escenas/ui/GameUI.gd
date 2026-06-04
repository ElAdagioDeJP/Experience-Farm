extends CanvasLayer

@onready var modal: Control = $CropModal
@onready var dimmer: ColorRect = $CropModal/Dimmer
@onready var panel: Panel = $CropModal/PergaminoPanel
@onready var close_button: Button = $CropModal/PergaminoPanel/CloseButton
@onready var crop_icon_rect: TextureRect = $CropModal/PergaminoPanel/CropIconRect
@onready var open_image_button: Button = $CropModal/PergaminoPanel/OpenImageButton
@onready var title_label: Label = $CropModal/PergaminoPanel/TitleLabel
@onready var subtitle_label: Label = $CropModal/PergaminoPanel/SubtitleLabel
@onready var description_label: RichTextLabel = $CropModal/PergaminoPanel/DescriptionLabel
@onready var history_label: RichTextLabel = $CropModal/PergaminoPanel/HistoryLabel
@onready var region_label: Label = $CropModal/PergaminoPanel/RegionLabel
@onready var image_modal: Control = $ImageModal
@onready var image_panel: Panel = $ImageModal/ImagePanel
@onready var image_dimmer: ColorRect = $ImageModal/ImageDimmer
@onready var image_close_button: Button = $ImageModal/ImagePanel/ImageCloseButton
@onready var image_texture: TextureRect = $ImageModal/ImagePanel/ImageTexture
@onready var tooltip: Panel = $Tooltip
@onready var tooltip_label: Label = $Tooltip/TooltipLabel

var screen_size: Vector2
var modal_open: bool = false
var slide_tween: Tween
var tooltip_tween: Tween
const PANEL_W: float = 860.0
const PANEL_H: float = 620.0
const ICON_BOX_POS: Vector2 = Vector2(20, 20)
const ICON_BOX_SIZE: Vector2 = Vector2(180, 150)


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2(-720, screen_size.y - 20)
	modal.visible = false
	dimmer.visible = false
	image_modal.visible = false
	tooltip.visible = false
	close_button.pressed.connect(hide_crop_modal)
	open_image_button.pressed.connect(show_image_modal)
	image_close_button.pressed.connect(hide_image_modal)
	image_dimmer.gui_input.connect(_on_image_dimmer_input)
	crop_icon_rect.gui_input.connect(_on_crop_icon_input)
	_set_estilo_ui()
	_ajustar_modal_imagen()


func _process(_delta: float) -> void:
	if screen_size != get_viewport().get_visible_rect().size:
		screen_size = get_viewport().get_visible_rect().size
		_ajustar_modal_imagen()
	if tooltip.visible:
		tooltip.position = get_viewport().get_mouse_position() + Vector2(16, 18)


func show_crop_modal(cname: String, subtitle: String, desc: String, history: String, region: String, icon_path: String = "") -> void:
	if modal_open:
		return
	hide_crop_tooltip()
	modal_open = true
	modal.visible = true
	dimmer.visible = true
	title_label.text = cname.to_upper()
	subtitle_label.text = subtitle
	description_label.text = desc
	history_label.text = "[i]📜 %s[/i]" % history
	region_label.text = "📍 %s" % region
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path) as Texture2D
		_ajustar_icono_modal(tex)
		open_image_button.visible = true
	else:
		crop_icon_rect.texture = null
		crop_icon_rect.visible = false
		open_image_button.visible = false
	if slide_tween:
		slide_tween.kill()
	slide_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	slide_tween.tween_property(panel, "position", Vector2(20, screen_size.y - PANEL_H - 20.0), 0.35)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hide_crop_modal() -> void:
	if not modal_open:
		return
	if slide_tween:
		slide_tween.kill()
	hide_crop_tooltip()
	hide_image_modal()
	slide_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	slide_tween.tween_property(panel, "position", Vector2(-720, screen_size.y - 20), 0.3)
	slide_tween.tween_callback(func() -> void:
		modal.visible = false
		dimmer.visible = false
		modal_open = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	)


func show_crop_tooltip(cname: String, _world_pos: Vector3) -> void:
	if modal_open:
		return
	tooltip_label.text = cname
	tooltip.modulate.a = 0.0
	tooltip.visible = true
	if tooltip_tween:
		tooltip_tween.kill()
	tooltip_tween = create_tween()
	tooltip_tween.tween_property(tooltip, "modulate:a", 1.0, 0.15)


func hide_crop_tooltip() -> void:
	if tooltip_tween:
		tooltip_tween.kill()
	tooltip.visible = false


func show_image_modal() -> void:
	if crop_icon_rect.texture == null:
		return
	image_texture.texture = crop_icon_rect.texture
	image_modal.visible = true


func hide_image_modal() -> void:
	image_modal.visible = false


func _on_crop_icon_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		show_image_modal()


func _on_image_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hide_image_modal()


func _ajustar_modal_imagen() -> void:
	var panel_w: float = minf(screen_size.x * 0.9, 1100.0)
	var panel_h: float = minf(screen_size.y * 0.82, 760.0)
	image_panel.position = Vector2((screen_size.x - panel_w) * 0.5, (screen_size.y - panel_h) * 0.5)
	image_panel.size = Vector2(panel_w, panel_h)
	image_close_button.position = Vector2(panel_w - 40.0, 10.0)
	image_close_button.size = Vector2(30.0, 30.0)
	image_texture.position = Vector2(20.0, 20.0)
	image_texture.size = Vector2(panel_w - 40.0, panel_h - 40.0)


func _set_estilo_ui() -> void:
	dimmer.color = Color("00000066")
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("F2E8C9")
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color("8B6347")
	panel_style.shadow_size = 12
	panel_style.shadow_color = Color("0000004D")
	panel_style.shadow_offset = Vector2(4, 4)
	panel.add_theme_stylebox_override("panel", panel_style)
	image_panel.add_theme_stylebox_override("panel", panel_style)

	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color("F2E8C9")
	tooltip_style.border_color = Color("3D2510")
	tooltip_style.border_width_left = 1
	tooltip_style.border_width_top = 1
	tooltip_style.border_width_right = 1
	tooltip_style.border_width_bottom = 1
	tooltip_style.corner_radius_top_left = 4
	tooltip_style.corner_radius_top_right = 4
	tooltip_style.corner_radius_bottom_left = 4
	tooltip_style.corner_radius_bottom_right = 4
	tooltip.add_theme_stylebox_override("panel", tooltip_style)

	title_label.add_theme_color_override("font_color", Color("3D2510"))
	subtitle_label.add_theme_color_override("font_color", Color("6B4226"))
	region_label.add_theme_color_override("font_color", Color("6B4226"))
	open_image_button.add_theme_color_override("font_color", Color("3D2510"))
	tooltip_label.add_theme_color_override("font_color", Color("3D2510"))
	description_label.add_theme_color_override("default_color", Color("2A1A0E"))
	history_label.add_theme_color_override("default_color", Color("4A2F1E"))


func _ajustar_icono_modal(tex: Texture2D) -> void:
	if tex == null:
		crop_icon_rect.texture = null
		crop_icon_rect.visible = false
		return

	crop_icon_rect.texture = tex
	crop_icon_rect.visible = true

	var src: Vector2 = tex.get_size()
	if src.x <= 0.0 or src.y <= 0.0:
		crop_icon_rect.position = ICON_BOX_POS
		crop_icon_rect.size = ICON_BOX_SIZE
		return

	var factor: float = minf(ICON_BOX_SIZE.x / src.x, ICON_BOX_SIZE.y / src.y)
	var draw_size: Vector2 = src * factor
	crop_icon_rect.position = ICON_BOX_POS + (ICON_BOX_SIZE - draw_size) * 0.5
	crop_icon_rect.size = draw_size
