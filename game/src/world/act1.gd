extends Node3D
## Act 1 director: the cavern. Follow the butterflies, don't get caught.
##
## Beats: land -> Wren warns -> butterflies guide -> hollows hide ->
## two ghost grounds -> white door. Caught = scare + checkpoint respawn,
## never death. docs/worlds.md: every scare has a fair tell, hiding is free.

enum S { INTRO, PLAY, CAUGHT, END }

const CavernScript := preload("res://src/world/cavern.gd")

var state: int = S.INTRO
var _spawn := Vector3(0, 0.1, 2)
var _grace_t := 0.0
var _caught_busy := false

@onready var player: Player = $Player
@onready var wren: Node3D = $Wren
@onready var cavern: Node3D = $Cavern
@onready var ghost_a: Ghost = $GhostA
@onready var ghost_b: Ghost = $GhostB

var _ui: CanvasLayer
var _fade: ColorRect
var _sub: Label
var _prompt: Label
var _obj: Label
var _stam_bg: ColorRect
var _stam_fg: ColorRect
var _flash: ColorRect
var _card: CenterContainer
var _card_label: Label

var _beats: Array = []
var _lines: Array[String] = []
var _showing := false
var _say_t := 0.0
var _checkpoints: Array[Vector3] = []
var _cp_idx := 0


func _ready() -> void:
	player.teleport(_spawn.x, _spawn.y, _spawn.z, 0.0)
	player.can_move = true
	player.stamina_enabled = true
	player.stamina = 1.0
	player.exhausted = false
	wren.call("follow", player)
	ghost_a.setup(player, self, [Vector3(5, 0, -11), Vector3(1.5, 0, -15), Vector3(7, 0, -17), Vector3(4, 0, -13)])
	ghost_b.setup(player, self, [Vector3(2, 0, -27), Vector3(-1.5, 0, -31), Vector3(4.5, 0, -32), Vector3(1, 0, -29)])
	_build_ui()
	_build_beats()
	_checkpoints = [Vector3(5, 0.1, -14), Vector3(2, 0.1, -30)]
	AudioDirector.play_cavern_drone()
	_fade.color.a = 1.0
	_fade_to(0.0, 2.5)
	_say("...cold. Stone under your hands. Wren is holding your sleeve.")
	state = S.PLAY


func _build_beats() -> void:
	_beats = [
		{"pos": Vector3(0, 0, 0), "r": 5.0, "done": false, "lines": [
			"WREN: Don't run. They hear running.",
			"YOU: ...who?",
			"WREN: The lost ones. Kids nobody came back for."]},
		{"pos": Vector3(0, 0, -8), "r": 3.5, "done": false, "lines": [
			"WREN: White ones. They remember the way out.",
			"WREN: Follow them. Not me."]},
		{"pos": Vector3(3.4, 0, -10.5), "r": 4.5, "done": false, "lines": [
			"WREN: Hollow rocks. Crouch inside and be small.",
			"WREN: They can't see small."]},
		{"pos": Vector3(5, 0, -14), "r": 3.5, "done": false, "lines": [
			"checkpoint. The butterflies wait for you.",
			"WREN: It walks here. Run past, or hide. Don't let it touch you."]},
		{"pos": Vector3(-4, 0, -22), "r": 4.0, "done": false, "lines": [
			"WREN: My legs are short too. Breathe.",
			"WREN: The door is real. Keep going."]},
		{"pos": Vector3(2, 0, -30), "r": 3.5, "done": false, "lines": [
			"checkpoint. Almost through.",
			"WREN: One more. It knows we're close. It always knows."]},
	]


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)

	_obj = Label.new()
	_obj.add_theme_font_size_override("font_size", 13)
	_obj.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 0.9))
	_obj.position = Vector2(12, 8)
	_obj.text = "follow the white butterflies  ·  run only when seen"
	_ui.add_child(_obj)

	_sub = Label.new()
	_sub.add_theme_font_size_override("font_size", 16)
	_sub.add_theme_color_override("font_color", Color(0.92, 0.92, 0.90))
	_sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_sub.add_theme_constant_override("shadow_offset_x", 1)
	_sub.add_theme_constant_override("shadow_offset_y", 2)
	_sub.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sub.position = Vector2(-300, -70)
	_sub.size = Vector2(600, 60)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ui.add_child(_sub)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-300, -34)
	_prompt.size = Vector2(600, 24)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(_prompt)

	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.5)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.position = Vector2(-1, -1)
	dot.size = Vector2(3, 3)
	_ui.add_child(dot)

	# stamina ("breath"): thin bar, bottom-left. Red when exhausted.
	var cap := Label.new()
	cap.add_theme_font_size_override("font_size", 11)
	cap.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	cap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	cap.position = Vector2(12, -46)
	cap.text = "breath"
	_ui.add_child(cap)
	_stam_bg = ColorRect.new()
	_stam_bg.color = Color(0, 0, 0, 0.55)
	_stam_bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stam_bg.position = Vector2(12, -30)
	_stam_bg.size = Vector2(124, 10)
	_ui.add_child(_stam_bg)
	_stam_fg = ColorRect.new()
	_stam_fg.color = Color(0.75, 0.85, 0.95, 0.9)
	_stam_fg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stam_fg.position = Vector2(14, -28)
	_stam_fg.size = Vector2(120, 6)
	_ui.add_child(_stam_fg)

	var vhs := ColorRect.new()
	vhs.set_anchors_preset(Control.PRESET_FULL_RECT)
	vhs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vhs.material = ShaderMaterial.new()
	(vhs.material as ShaderMaterial).shader = preload("res://shaders/vhs_overlay.gdshader")
	_ui.add_child(vhs)

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.9, 0.92, 0.95, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_flash)

	_card = CenterContainer.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.visible = false
	_ui.add_child(_card)
	_card_label = Label.new()
	_card_label.add_theme_font_size_override("font_size", 34)
	_card_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.97))
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.add_child(_card_label)

	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fade)


func _say(text: String) -> void:
	_lines.append(text)


func _fade_to(alpha: float, dur := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, dur)


# ---------------------------------------------------------------- frame

func _process(delta: float) -> void:
	_pump_lines(delta)

	if state == S.PLAY:
		_check_beats()
		_check_checkpoints()
		_check_exit()
		_poll_chase_music()
		_update_stamina_hud()
		if is_player_hidden():
			_prompt.text = "hidden — stay small, stay quiet"
		elif _prompt.text == "hidden — stay small, stay quiet":
			_prompt.text = ""
		if _grace_t > 0.0:
			_grace_t -= delta
			if _grace_t <= 0.0:
				ghost_a.grace = false
				ghost_b.grace = false

	if state == S.END and Input.is_action_just_pressed("interact"):
		get_tree().reload_current_scene()


func _pump_lines(delta: float) -> void:
	if _showing:
		_say_t -= delta
		if _say_t <= 0.0:
			_showing = false
			_sub.text = ""
	elif not _lines.is_empty():
		_sub.text = _lines.pop_front()
		_showing = true
		_say_t = 3.4


func _check_beats() -> void:
	for b in _beats:
		if bool(b["done"]):
			continue
		var pp: Vector3 = player.global_position
		var bp: Vector3 = b["pos"]
		pp.y = 0.0
		bp.y = 0.0
		if pp.distance_to(bp) < float(b["r"]):
			b["done"] = true
			for line in b["lines"]:
				_say(line)


func _check_checkpoints() -> void:
	if _cp_idx >= _checkpoints.size():
		return
	var pp: Vector3 = player.global_position
	var cp: Vector3 = _checkpoints[_cp_idx]
	pp.y = 0.0
	cp.y = 0.0
	if pp.distance_to(cp) < 2.5:
		_spawn = _checkpoints[_cp_idx]
		_cp_idx += 1
		_say("checkpoint. Wren squeezes your hand.")


func _check_exit() -> void:
	var pp: Vector3 = player.global_position
	pp.y = 0.0
	if pp.distance_to(Vector3(0, 0, -38)) < 2.0:
		_finish()


func _poll_chase_music() -> void:
	if ghost_a.is_chasing() or ghost_b.is_chasing():
		AudioDirector.play_chase()
		_prompt.text = "IT SEES YOU — RUN"
	else:
		AudioDirector.stop_chase()
		if _prompt.text == "IT SEES YOU — RUN":
			_prompt.text = ""


func _update_stamina_hud() -> void:
	_stam_fg.size.x = 120.0 * clampf(player.stamina, 0.0, 1.0)
	if player.exhausted:
		_stam_fg.color = Color(0.9, 0.25, 0.2, 0.95)
	else:
		_stam_fg.color = Color(0.75, 0.85, 0.95, 0.9)


## Crouched inside a hollow rock: invisible. The hide verb.
func is_player_hidden() -> bool:
	if InputSetup.current_state() != InputSetup.MoveState.CROUCH:
		return false
	var pp: Vector3 = player.global_position
	for h in CavernScript.HIDE_SPOTS:
		var q: Vector3 = h
		pp.y = 0.0
		q.y = 0.0
		if pp.distance_to(q) < CavernScript.HIDE_RADIUS:
			return true
	return false


# ---------------------------------------------------------------- caught + ending

func caught_by(_g: Ghost) -> void:
	if state != S.PLAY or _caught_busy:
		return
	_caught_busy = true
	state = S.CAUGHT
	AudioDirector.play_caught()
	_flash.color = Color(0.92, 0.94, 0.97, 0.9)
	get_tree().paused = true
	await get_tree().create_timer(0.55, true, false, true).timeout
	get_tree().paused = false
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.4)
	AudioDirector.stop_chase()
	_fade_to(1.0, 0.8)
	await get_tree().create_timer(0.9).timeout
	# respawn at checkpoint, ghosts back to patrol, 3 s of grace
	player.teleport(_spawn.x, _spawn.y, _spawn.z, 0.0)
	player.stamina = 1.0
	player.exhausted = false
	wren.global_position = _spawn + Vector3(-0.9, 0, -0.5)
	ghost_a.reset()
	ghost_b.reset()
	ghost_a.grace = true
	ghost_b.grace = true
	_grace_t = 3.0
	_lines.clear()
	_showing = false
	_sub.text = ""
	_say("...dark. Then Wren's voice. \"Get up. It didn't keep you.\"")
	_fade_to(0.0, 1.5)
	state = S.PLAY
	_caught_busy = false


func _finish() -> void:
	if state != S.PLAY:
		return
	state = S.END
	AudioDirector.stop_chase()
	AudioDirector.stop_music()
	player.can_move = false
	_card.visible = true
	_card_label.text = "THE 30TH IS WAITING\n\nto be continued  ·  [E] walk it again"
	_fade_to(0.0, 2.0)
	_say("WREN: See? The butterflies knew.")


func _unhandled_input(event: InputEvent) -> void:
	if state == S.END and event is InputEventKey:
		if (event as InputEventKey).physical_keycode == KEY_R and event.is_pressed():
			get_tree().reload_current_scene()
