extends Control
class_name PauseMenu
## ESC pause / settings overlay.
##
## Self-contained: it pauses the SceneTree, frees the mouse, and restores both
## when it closes. Scenes only need to add it to their UI layer; no callback is
## required. Authored in 1280x720 units and scaled by 0.25, the same trick the
## DialogueBox uses, so labels are not magnified by the 320x180 stretch.
##
## docs/tech-stack.md -- settings live on GameState so they survive scene loads.

signal resumed

var _panel: PanelContainer
var _sens: HSlider
var _vol: HSlider
var _resume_btn: Button

var _is_open := false
var _prev_paused := false
var _prev_mouse: Input.MouseMode = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	scale = Vector2(0.25, 0.25)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(430, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.035, 0.045, 0.97)
	style.border_color = Color(0.62, 0.64, 0.70, 0.85)
	style.set_border_width_all(3)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_panel.add_child(col)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.92, 0.90, 0.83))
	col.add_child(title)

	var rule := ColorRect.new()
	rule.color = Color(0.55, 0.57, 0.62, 0.7)
	rule.custom_minimum_size = Vector2(0, 2)
	col.add_child(rule)

	col.add_child(_label("MOUSE SENSITIVITY"))
	_sens = HSlider.new()
	_sens.min_value = 0.4
	_sens.max_value = 3.0
	_sens.step = 0.1
	_sens.value = float(GameState.mouse_sensitivity)
	_sens.custom_minimum_size = Vector2(358, 22)
	_sens.value_changed.connect(_on_sensitivity)
	col.add_child(_sens)

	col.add_child(_label("VOLUME"))
	_vol = HSlider.new()
	_vol.min_value = 0.0
	_vol.max_value = 1.0
	_vol.step = 0.05
	_vol.value = float(GameState.master_volume)
	_vol.custom_minimum_size = Vector2(358, 22)
	_vol.value_changed.connect(_on_volume)
	col.add_child(_vol)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)

	_resume_btn = _button("RESUME")
	_resume_btn.pressed.connect(close)
	col.add_child(_resume_btn)

	var quit := _button("QUIT")
	quit.pressed.connect(func() -> void: get_tree().quit())
	col.add_child(quit)

	var hint := Label.new()
	hint.text = "ESC to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.65, 0.67, 0.72))
	col.add_child(hint)

	_apply_volume(float(GameState.master_volume))


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.80, 0.82, 0.86))
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(358, 40)
	b.add_theme_font_size_override("font_size", 20)
	b.focus_mode = Control.FOCUS_ALL
	return b


# ---------------------------------------------------------------- public

func is_open() -> bool:
	return _is_open


func open() -> void:
	if _is_open:
		return
	_is_open = true
	_prev_paused = get_tree().paused
	_prev_mouse = Input.mouse_mode
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_resume_btn.grab_focus()


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	get_tree().paused = _prev_paused
	Input.mouse_mode = _prev_mouse
	resumed.emit()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	var key := event as InputEventKey
	if key.physical_keycode != KEY_ESCAPE and key.keycode != KEY_ESCAPE:
		return
	# While visible the menu owns ESC. While hidden it opens on ESC, which is
	# the global pause binding from InputSetup. Consume it either way so no
	# scene also reacts to the same press.
	get_viewport().set_input_as_handled()
	if _is_open:
		close()
	else:
		open()


# ---------------------------------------------------------------- settings

func _on_sensitivity(v: float) -> void:
	GameState.mouse_sensitivity = v


func _on_volume(v: float) -> void:
	GameState.master_volume = v
	_apply_volume(v)


func _apply_volume(v: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, v <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.001)))
