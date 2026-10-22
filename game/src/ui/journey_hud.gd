extends CanvasLayer
class_name JourneyHUD
## Shared HUD for the three 30th worlds and the ending. Built in code.
## Keeps the VHS overlay, subtitle queue, breath bar and end card in one
## place so world directors stay about worlds, not widgets.

var sub_label: Label
var objective_label: Label
var prompt_label: Label
var card_label: Label
var card: CenterContainer
var fade: ColorRect

var _stam_bg: ColorRect
var _stam_fg: ColorRect
var _flash: ColorRect
var _lines: Array[String] = []
var _showing := false
var _say_t := 0.0
var _has_stamina := true


func setup(with_stamina: bool) -> void:
	_has_stamina = with_stamina
	layer = 5
	# Tweens and the subtitle pump must keep running through the 0.55 s
	# caught freeze, or the fade stalls mid-scare.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	objective_label = Label.new()
	objective_label.add_theme_font_size_override("font_size", 13)
	objective_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.94, 0.9))
	objective_label.position = Vector2(12, 8)
	add_child(objective_label)

	sub_label = Label.new()
	sub_label.add_theme_font_size_override("font_size", 16)
	sub_label.add_theme_color_override("font_color", Color(0.93, 0.93, 0.90))
	sub_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	sub_label.add_theme_constant_override("shadow_offset_x", 1)
	sub_label.add_theme_constant_override("shadow_offset_y", 2)
	sub_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	sub_label.position = Vector2(-300, -70)
	sub_label.size = Vector2(600, 60)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(sub_label)

	prompt_label = Label.new()
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-300, -34)
	prompt_label.size = Vector2(600, 24)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(prompt_label)

	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.5)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.position = Vector2(-1, -1)
	dot.size = Vector2(3, 3)
	add_child(dot)

	if _has_stamina:
		var cap := Label.new()
		cap.add_theme_font_size_override("font_size", 11)
		cap.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		cap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		cap.position = Vector2(12, -46)
		cap.text = "breath"
		add_child(cap)
		_stam_bg = ColorRect.new()
		_stam_bg.color = Color(0, 0, 0, 0.55)
		_stam_bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_stam_bg.position = Vector2(12, -30)
		_stam_bg.size = Vector2(124, 10)
		add_child(_stam_bg)
		_stam_fg = ColorRect.new()
		_stam_fg.color = Color(0.75, 0.85, 0.95, 0.9)
		_stam_fg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_stam_fg.position = Vector2(14, -28)
		_stam_fg.size = Vector2(120, 6)
		add_child(_stam_fg)

	var vhs := ColorRect.new()
	vhs.set_anchors_preset(Control.PRESET_FULL_RECT)
	vhs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vhs.material = ShaderMaterial.new()
	(vhs.material as ShaderMaterial).shader = preload("res://shaders/vhs_overlay.gdshader")
	add_child(vhs)

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.92, 0.94, 0.97, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	card = CenterContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.visible = false
	add_child(card)
	card_label = Label.new()
	card_label.add_theme_font_size_override("font_size", 22)
	card_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.97))
	card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(card_label)

	fade = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)


func _process(delta: float) -> void:
	if _showing:
		_say_t -= delta
		if _say_t <= 0.0:
			_showing = false
			sub_label.text = ""
	elif not _lines.is_empty():
		sub_label.text = _lines.pop_front()
		_showing = true
		_say_t = 3.4


func say(text: String) -> void:
	_lines.append(text)


func clear_say() -> void:
	_lines.clear()
	_showing = false
	sub_label.text = ""


func objective(text: String) -> void:
	objective_label.text = text


func prompt(text: String) -> void:
	prompt_label.text = text


func set_stamina(v: float, exhausted: bool) -> void:
	if _stam_fg == null:
		return
	_stam_fg.size.x = 120.0 * clampf(v, 0.0, 1.0)
	_stam_fg.color = Color(0.9, 0.25, 0.2, 0.95) if exhausted else Color(0.75, 0.85, 0.95, 0.9)


func fade_to(alpha: float, dur := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", alpha, dur)


func flash_sting(a := 0.9, col := Color(0.95, 0.96, 0.98)) -> void:
	_flash.color = Color(col.r, col.g, col.b, a)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.45)


func end_card(title: String, sub: String) -> void:
	card.visible = true
	card_label.text = title + "\n\n" + sub
	# Above the fade, so the last card is not dimmed by the black overlay.
	card.move_to_front()


func hide_card() -> void:
	card.visible = false
