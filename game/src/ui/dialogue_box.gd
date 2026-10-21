extends Control
class_name DialogueBox
## The one proper dialogue/choice box in the game. docs/prologue.md Beat 7:
## "the player gets a dialogue box with choice options. This is the only time
## in the game it is used in this form."
##
## Dumb on purpose: it shows lines, then options, and emits signals. The
## scene owns the branching (prologue.gd _DLG). No globals, no autoload.
##
## Input while visible: E / Enter / Space advances or confirms; W/S or
## arrows move the cursor; mouse click picks directly. Works on touch too
## (buttons are real Buttons).

signal line_finished
signal option_chosen(index: int)

const CHARS_PER_SEC := 46.0
const SPEAKER_COLOURS := {
	"WREN": Color(0.86, 0.88, 0.95),
	"YOU": Color(0.95, 0.86, 0.70),
	"MUM": Color(0.90, 0.62, 0.58),
}

var _panel: PanelContainer
var _speaker_label: Label
var _text_label: Label
var _options_box: VBoxContainer
var _hint: Label

var _lines: Array[String] = []
var _line_i := 0
var _choices: Array[String] = []
var _sel := 0
var _choosing := false
var _pending_choices := false
var _typing := false
var _full := ""
var _shown := 0.0
var _buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()


func _build() -> void:
	# A padded dark panel across the lower third. No rounded corners, no
	# gradients: this should look printed on a bad VHS tape.
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.position = Vector2(-330, -168)
	_panel.custom_minimum_size = Vector2(660, 140)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.025, 0.93)
	style.border_color = Color(0.55, 0.57, 0.62, 0.75)
	style.set_border_width_all(2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_panel.add_child(col)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 12)
	_speaker_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
	col.add_child(_speaker_label)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 16)
	_text_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.92))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(620, 44)
	col.add_child(_text_label)

	_options_box = VBoxContainer.new()
	_options_box.add_theme_constant_override("separation", 2)
	col.add_child(_options_box)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color(0.72, 0.74, 0.78, 0.85))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint)


# ---------------------------------------------------------------- public

## One or more spoken lines. Emits line_finished after the last is advanced.
func show_lines(speaker: String, lines: Array) -> void:
	_choices.clear()
	_choosing = false
	_pending_choices = false
	_lines.clear()
	for l in lines:
		_lines.append(str(l))
	_line_i = 0
	_set_speaker(speaker)
	_clear_options()
	visible = true
	_hint.text = "E / click  ▸"
	_begin_line()


## A spoken line followed by options. Emits option_chosen(index).
func show_choice(speaker: String, line: String, options: Array) -> void:
	_lines = [line]
	_line_i = 0
	_choices.clear()
	for o in options:
		_choices.append(str(o))
	_choosing = false
	_pending_choices = true
	_set_speaker(speaker)
	visible = true
	_hint.text = ""
	_begin_line()


func close() -> void:
	visible = false
	_typing = false
	_choosing = false
	_pending_choices = false
	_lines.clear()
	_choices.clear()
	_clear_options()


# ---------------------------------------------------------------- internals

func _set_speaker(sp: String) -> void:
	_speaker_label.text = sp
	_speaker_label.add_theme_color_override(
		"font_color", SPEAKER_COLOURS.get(sp, Color(0.8, 0.82, 0.88)))


func _begin_line() -> void:
	_full = _lines[_line_i] if _line_i < _lines.size() else ""
	_shown = 0.0
	_typing = true
	_text_label.text = ""
	_text_label.visible = true


func _process(delta: float) -> void:
	if not visible or not _typing:
		return
	_shown += CHARS_PER_SEC * delta
	var n := mini(int(_shown), _full.length())
	_text_label.text = _full.substr(0, n)
	if n >= _full.length():
		_typing = false
		_on_line_complete()


func _on_line_complete() -> void:
	if _pending_choices:
		_show_options()
	elif _line_i >= _lines.size() - 1:
		_hint.text = "E / click  ▸"
	else:
		_hint.text = "E / click  ▸"


func _advance() -> void:
	if not visible:
		return
	if _typing:
		# First press completes the typewriter. Second press moves on.
		_shown = float(_full.length())
		_text_label.text = _full
		_typing = false
		_on_line_complete()
		return
	if _choosing:
		_pick(_sel)
		return
	if _line_i < _lines.size() - 1:
		_line_i += 1
		_begin_line()
	else:
		visible = false
		line_finished.emit()


func _show_options() -> void:
	_choosing = true
	_pending_choices = false
	_clear_options()
	_hint.text = "W/S  ▸  E / click"
	for i in range(_choices.size()):
		var b := Button.new()
		b.text = "   " + _choices[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_color", Color(0.80, 0.81, 0.85))
		b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		b.pressed.connect(_pick.bind(i))
		b.mouse_entered.connect(_set_sel.bind(i))
		_options_box.add_child(b)
		_buttons.append(b)
	_sel = 0
	_paint_selection()


func _clear_options() -> void:
	for b in _buttons:
		if is_instance_valid(b):
			b.queue_free()
	_buttons.clear()
	for c in _options_box.get_children():
		c.queue_free()
	_sel = 0


func _set_sel(i: int) -> void:
	if not _choosing or i < 0 or i >= _buttons.size():
		return
	_sel = i
	_paint_selection()


func _paint_selection() -> void:
	for i in range(_buttons.size()):
		var on := i == _sel
		var b: Button = _buttons[i]
		b.text = (" ▸ " if on else "   ") + _choices[i]
		b.add_theme_color_override(
			"font_color",
			Color(1.0, 0.98, 0.90) if on else Color(0.66, 0.68, 0.72))


func _pick(i: int) -> void:
	if not _choosing or i < 0 or i >= _choices.size():
		return
	_choosing = false
	visible = false
	_clear_options()
	option_chosen.emit(i)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var k: int = (event as InputEventKey).physical_keycode
		if k == KEY_W or k == KEY_UP:
			_set_sel((_sel - 1 + _buttons.size()) % maxi(1, _buttons.size()))
			get_viewport().set_input_as_handled()
		elif k == KEY_S or k == KEY_DOWN:
			_set_sel((_sel + 1) % maxi(1, _buttons.size()))
			get_viewport().set_input_as_handled()
		elif k == KEY_E or k == KEY_ENTER or k == KEY_SPACE:
			_advance()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.is_pressed():
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not _choosing:
			_advance()
			get_viewport().set_input_as_handled()
