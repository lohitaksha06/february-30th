extends Node3D
## Prologue Part 1 director: wake in bed -> knocks -> wardrobe -> Wren -> push -> FALL.
## docs/prologue.md beats 1,4,6,8,9 compressed to ~6 minutes. No enemies.
## Everything is script-driven. Player only walks / looks / presses E.

enum S { SELECT, LYING, SITUP, CLOCK, LIVING, EXPLORE, KNOCK, DOOR_OPEN, TALK, MOM, FALL, TITLE }

var state: int = S.SELECT
var _t := 0.0
var _knock_done := false
var _mom_timer := 0.0
var _push_window := 0.0
var _wake_ready := false
var _clock_done := false
var _seen_cake := false
var _knock_ready := false
var _title_t := 0.0
var _going := false
var _mouse_free := true

@onready var player: CharacterBody3D = $Player
@onready var wren: Node3D = $Wren
@onready var clock3d: Label3D = $Clock3D

var _ui: CanvasLayer
var _fade: ColorRect
var _sub: Label
var _prompt: Label
var _hud_clock: Label
var _flash: ColorRect
var _title: CenterContainer
var _title_bg: ColorRect
var _title_label: Label
var _title_sub: Label
var _title_prompt: Label
var _choice_box: VBoxContainer
var _select_title: Label
var _select_sub: Label
var _dlg: DialogueBox
var _pause: PauseMenu

var _cam: Camera3D
var _door: Node3D
var _streetlight: DirectionalLight3D
var _house: Node3D
var _tunnel: Node3D
var _shake := 0.0
var _fade_tw: Tween


func _ready() -> void:
	GameState.reset_prologue()
	# 11:59, not 11:48: the first thing the child says is "one more minute".
	Clock.set_time(11, 59)
	clock3d.text = "11:59"
	_cam = player.get_node("Head/Camera3D") as Camera3D
	_house = get_node("House") as Node3D
	_find_door()
	_find_streetlight()
	_build_ui()
	_build_tunnel()
	_start_select()


# ---------------------------------------------------------------- setup

func _find_door() -> void:
	_door = get_node_or_null("House/WardrobeDoor") as Node3D
	if _door == null:
		_door = _search(get_node("House"), "WardrobeDoor") as Node3D


func _search(n: Node, target: String) -> Node:
	if n.name == target:
		return n
	for c in n.get_children():
		var r := _search(c, target)
		if r != null:
			return r
	return null


func _find_streetlight() -> void:
	for c in get_node("House").get_children():
		if c is DirectionalLight3D:
			_streetlight = c


func _build_tunnel() -> void:
	# The fall: a long dark shaft behind the wardrobe. Hidden until PUSH.
	_tunnel = Node3D.new()
	_tunnel.name = "FallTunnel"
	_tunnel.visible = false
	# Wardrobe back is at approx (3.0, *, 0.2). Tunnel extends -Z behind it.
	_tunnel.position = Vector3(3.0, 1.2, 0.2)
	add_child(_tunnel)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.02, 0.03)
	mat.roughness = 1.0
	for i in range(14):
		var ring := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.2, 2.6, 0.25)
		ring.mesh = bm
		# hollow illusion: big box with dark mat, camera flies through centre gap?
		# cheaper: 4 planes per ring would be 56 nodes; instead use one inverted box per 4m.
		ring.material_override = mat
		ring.position = Vector3(0, 0, -2.0 - i * 2.0)
		_tunnel.add_child(ring)
	# calendar pages floating past during fall (white quads, red tint light)
	var page_mat := StandardMaterial3D.new()
	page_mat.albedo_color = Color(0.85, 0.82, 0.78)
	page_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(24):
		var p := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.4, 0.55)
		p.mesh = q
		p.material_override = page_mat
		p.position = Vector3(randf_range(-0.8, 0.8), randf_range(-1.0, 1.0), -1.0 - i * 1.3)
		p.rotation_degrees = Vector3(randf_range(-30, 30), randf_range(0, 90), randf_range(-20, 20))
		_tunnel.add_child(p)
	var red := OmniLight3D.new()
	red.light_color = Color(0.9, 0.15, 0.12)
	red.light_energy = 1.2
	red.omni_range = 9.0
	red.shadow_enabled = false
	red.position = Vector3(0, 0.5, -6)
	_tunnel.add_child(red)


# ---------------------------------------------------------------- UI (built in code so the .tscn stays tiny)

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "UI"
	add_child(_ui)

	_hud_clock = Label.new()
	_hud_clock.name = "ClockHUD"
	_hud_clock.text = "FEB 29  11:59"
	_hud_clock.add_theme_font_size_override("font_size", 6)
	_hud_clock.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 0.85))
	_hud_clock.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud_clock.position = Vector2(6, 4)
	_ui.add_child(_hud_clock)

	# Text sizes are in the 320x180 canvas base. The old 13/16/14 sizes were
	# magnified 4x to 52/64/56 px on a 720p window -- enormous.
	_sub = Label.new()
	_sub.name = "Subtitle"
	_sub.add_theme_font_size_override("font_size", 7)
	_sub.add_theme_color_override("font_color", Color(0.92, 0.92, 0.90))
	_sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_sub.add_theme_constant_override("shadow_offset_x", 1)
	_sub.add_theme_constant_override("shadow_offset_y", 2)
	_sub.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sub.position = Vector2(-150, -56)
	_sub.size = Vector2(300, 38)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ui.add_child(_sub)

	_prompt = Label.new()
	_prompt.name = "Prompt"
	_prompt.add_theme_font_size_override("font_size", 6)
	_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-150, -28)
	_prompt.size = Vector2(300, 18)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(_prompt)

	# crosshair dot
	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.5)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.position = Vector2(-1, -1)
	dot.size = Vector2(3, 3)
	_ui.add_child(dot)

	# VHS overlay (analog horror, almost free)
	var vhs := ColorRect.new()
	vhs.name = "VHS"
	vhs.set_anchors_preset(Control.PRESET_FULL_RECT)
	vhs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vhs.material = ShaderMaterial.new()
	(vhs.material as ShaderMaterial).shader = preload("res://shaders/vhs_overlay.gdshader")
	_ui.add_child(vhs)

	# jumpscare flash (hidden)
	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.9, 0.05, 0.05, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_flash)

	# the one proper dialogue box. docs/prologue.md Beat 7.
	_dlg = DialogueBox.new()
	_dlg.name = "DialogueBox"
	_ui.add_child(_dlg)

	# choice buttons (boy / girl)
	_choice_box = VBoxContainer.new()
	_choice_box.set_anchors_preset(Control.PRESET_CENTER)
	_choice_box.position = Vector2(-45, -32)
	_choice_box.add_theme_constant_override("separation", 6)
	_ui.add_child(_choice_box)

	# Title lockup on the character-select screen. This is the first thing the
	# player sees, so it gets to look like the box art rather than a debug menu.
	_select_title = Label.new()
	_select_title.name = "SelectTitle"
	_select_title.text = "FEBRUARY 30th"
	_select_title.add_theme_font_size_override("font_size", 19)
	_select_title.add_theme_color_override("font_color", Color(0.80, 0.08, 0.09))
	_select_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_select_title.add_theme_constant_override("shadow_offset_x", 1)
	_select_title.add_theme_constant_override("shadow_offset_y", 2)
	_select_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_select_title.position = Vector2(-150, 14)
	_select_title.size = Vector2(300, 26)
	_select_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(_select_title)

	_select_sub = Label.new()
	_select_sub.name = "SelectSub"
	_select_sub.text = "the day after your birthday"
	_select_sub.add_theme_font_size_override("font_size", 6)
	_select_sub.add_theme_color_override("font_color", Color(0.66, 0.68, 0.72))
	_select_sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_select_sub.position = Vector2(-150, 38)
	_select_sub.size = Vector2(300, 12)
	_select_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(_select_sub)

	# title card (hidden). This is the post-fall card that leads into Act 1,
	# so it has to look like a chapter break, not the end of the game.
	# The black backdrop is a UI rect, not a hidden 3D world: hiding the
	# WorldEnvironment mid-frame crashed the GL capture and gained nothing.
	_title_bg = ColorRect.new()
	_title_bg.name = "TitleBg"
	_title_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_bg.color = Color(0.0, 0.0, 0.0, 1.0)
	_title_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_bg.visible = false
	_ui.add_child(_title_bg)

	_title = CenterContainer.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.visible = false
	_ui.add_child(_title)
	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 10)
	title_col.alignment = BoxContainer.ALIGNMENT_CENTER
	title_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_child(title_col)
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.88, 0.10, 0.10))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.text = "FEBRUARY 30th"
	title_col.add_child(_title_label)
	_title_sub = Label.new()
	_title_sub.add_theme_font_size_override("font_size", 8)
	_title_sub.add_theme_color_override("font_color", Color(0.82, 0.84, 0.88))
	_title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_sub.text = "ACT I — THE CAVERN"
	title_col.add_child(_title_sub)

	# The prompt needs to live inside the title column: the black title
	# backdrop is drawn above the HUD prompt, so the old label was hidden.
	_title_prompt = Label.new()
	_title_prompt.add_theme_font_size_override("font_size", 7)
	_title_prompt.add_theme_color_override("font_color", Color(0.64, 0.66, 0.70))
	_title_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_prompt.text = "[ENTER] continue        [R] replay"
	title_col.add_child(_title_prompt)

	# ESC settings. Added above the dialogue box and below the fade.
	_pause = PauseMenu.new()
	_pause.name = "PauseMenu"
	_ui.add_child(_pause)

	# fade (top-most)
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fade)


func _say(text: String, dur := 3.0) -> void:
	_sub.text = text
	_sub.modulate.a = 1.0
	await get_tree().create_timer(dur).timeout
	if _sub.text == text:
		_sub.text = ""


func _fade_to(alpha: float, dur := 1.0) -> void:
	# Kill the previous fade. Without this, the character-select fade-out and
	# the slow wake fade fight over the same property and the wake-in is lost.
	if _fade_tw != null and _fade_tw.is_valid():
		_fade_tw.kill()
	_fade_tw = create_tween()
	_fade_tw.tween_property(_fade, "color:a", alpha, dur)


# ---------------------------------------------------------------- beats

func _start_select() -> void:
	state = S.SELECT
	player.can_move = false
	# The buttons need a cursor. Nothing used to switch the mouse back on
	# after this screen, so mouse-look was dead for the whole prologue.
	_mouse_free = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_fade.color.a = 1.0
	_fade_to(0.0, 1.5)
	_select_title.visible = true
	_select_sub.visible = true
	_select_sub.text = "FEBRUARY 29th, 11:59 PM   ·   the day after your birthday"
	if not _select_title.has_meta("pulsing"):
		_select_title.set_meta("pulsing", true)
		var pulse := _select_title.create_tween().set_loops()
		pulse.tween_property(_select_title, "modulate:a", 0.62, 1.6)
		pulse.tween_property(_select_title, "modulate:a", 1.0, 1.6)
	for c in _choice_box.get_children():
		c.queue_free()
	_choice_box.visible = true
	var l := Label.new()
	l.text = "who are you?"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 8)
	_choice_box.add_child(l)
	var first: Button = null
	for g in ["boy", "girl"]:
		var b := Button.new()
		b.text = g.to_upper()
		b.custom_minimum_size = Vector2(104, 20)
		b.add_theme_font_size_override("font_size", 6)
		_style_choice_button(b)
		b.pressed.connect(_on_pick.bind(g))
		_choice_box.add_child(b)
		if first == null:
			first = b
	if first != null:
		first.grab_focus()


## The default engine button theme is grey and modern. This is a VHS-era
## menu: near-black, thin red keyline, pale type.
func _style_choice_button(b: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.045, 0.035, 0.040, 0.94)
	normal.border_color = Color(0.34, 0.09, 0.10)
	normal.set_border_width_all(1)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.13, 0.045, 0.050, 0.96)
	hover.border_color = Color(0.72, 0.16, 0.16)

	var focus := hover.duplicate() as StyleBoxFlat
	focus.border_color = Color(0.92, 0.72, 0.44)
	focus.set_border_width_all(2)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", Color(0.86, 0.82, 0.76))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.80))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.90, 0.80))


func _on_pick(g: String) -> void:
	if state != S.SELECT:
		return
	GameState.gender = g
	_mouse_free = false
	_select_title.visible = false
	_select_sub.visible = false
	player.capture_mouse()
	for c in _choice_box.get_children():
		c.queue_free()
	_choice_box.visible = false
	_start_lying()


func _start_lying() -> void:
	state = S.LYING
	# Hold the body before moving it: gravity would otherwise drop the capsule
	# to the floor during the fade-in, so the "lying down" shot was lost.
	player.set_physics_process(false)
	# Lying in bed: the camera rides 1.62 m above the body origin, so lower
	# the origin until the eye sits just above the mattress. (The old 0.78
	# put the eye at 2.4 m, almost touching the 2.6 m ceiling.)
	player.teleport(0.85, -0.55, 3.05, -0.15)
	player.can_move = false
	# Positive pitch looks UP in Godot (the old -1.02 was pitched at the bed,
	# which is why the first shot was a flat blue slab). Head on the pillow,
	# eye just above the mattress, ceiling and window in frame.
	player.set_pitch(0.62)
	_wake_ready = false
	_fade.color.a = 1.0
	_fade_to(0.0, 3.2)  # slow wake
	Clock.set_time(11, 59)
	clock3d.text = "11:59"
	AudioDirector.play_ambience()
	_say("You are awake. The ceiling. The streetlight moving across it.", 5.0)
	await get_tree().create_timer(3.6).timeout
	if state != S.LYING:
		return
	_wake_ready = true
	_prompt.text = "[E] sit up"


func _sit_up() -> void:
	if state != S.LYING or not _wake_ready:
		return
	state = S.SITUP
	_prompt.text = ""
	GameState.sat_up = true
	player.can_move = false
	# Sit up in place first. The old version snapped the eye and the body to a
	# standing spot in one frame, which read as a bug rather than waking up.
	# Mouse look is off for the tween so it cannot fight the animation.
	player.set_process_unhandled_input(false)
	var head := player.get_node("Head") as Node3D
	var tw := create_tween()
	tw.tween_property(head, "rotation:x", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1.5).timeout
	player.set_pitch(0.0)
	_fade_to(0.85, 0.45)
	await get_tree().create_timer(0.5).timeout
	player.teleport(1.75, 0.1, 1.35, -1.9)
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	_fade_to(0.0, 0.8)
	# The torch is yours from here. It is the only shadow map in the game,
	# and it is what makes the hallway read as depth instead of paint.
	player.set_flashlight(true)
	# Turn the player toward the clock. The old version told them to look at
	# it while the camera still faced the doorway, which read as a bug.
	player.look_at_point(clock3d.global_position)
	await get_tree().create_timer(0.55).timeout
	player.can_move = true
	state = S.CLOCK
	_prompt.text = "[E] check the clock"
	_say("The clock is still on. Look at it.", 4.0)


func _check_clock() -> void:
	if state != S.CLOCK or _clock_done:
		return
	_clock_done = true
	_prompt.text = ""
	player.look_at_point(clock3d.global_position)
	Clock.set_time(11, 59)
	clock3d.text = "11:59"
	_say("11:59. One more minute till my birthday.", 4.5)
	await get_tree().create_timer(3.2).timeout
	if state != S.CLOCK:
		return
	state = S.LIVING
	_say("Mum left the cake out. Eleven candles.", 4.0)


func _see_cake() -> void:
	if _seen_cake:
		return
	_seen_cake = true
	_prompt.text = ""
	player.look_at_point(Vector3(6.9, 0.95, 1.6))
	# The music box starts here, in the living room, in tune. docs/prologue.md
	# Beat 2: it is the only genuinely warm sound in the game.
	AudioDirector.play_musicbox_real()
	_say("Eleven candles. One for every year.", 4.0)
	await get_tree().create_timer(2.4).timeout
	if state != S.LIVING:
		return
	state = S.EXPLORE
	_t = 0.0
	_prompt.text = "go back to your room — the wardrobe  [WASD]   [F] torch"


func _process(delta: float) -> void:
	_t += delta
	_tick_clock_hud()
	_flicker(delta)

	if state == S.LYING and _wake_ready and Input.is_action_just_pressed("interact"):
		_sit_up()

	if state == S.CLOCK and not _clock_done:
		_prompt.text = "[E] check the clock"
		if Input.is_action_just_pressed("interact"):
			_check_clock()

	if state == S.LIVING and not _seen_cake:
		_prompt.text = "the cake is in the living room  [WASD walk]"
		if player.global_position.distance_to(Vector3(6.9, 0.0, 1.6)) < 2.4:
			_see_cake()

	if state == S.EXPLORE:
		_prompt.text = "go back to your room — the wardrobe  [WASD]   [F] torch"
		var near := player.global_position.distance_to(Vector3(3.0, 0.0, 0.9)) < 2.4
		if _t > 12.0 or (_t > 4.0 and near):
			_start_knocks()

	if state == S.KNOCK:
		if _knock_ready:
			_prompt.text = "[E] open the wardrobe"
			_check_wardrobe_early()

	if state == S.TITLE:
		_title_t += delta
		# Never leave a player staring at what looks like an end card: if they
		# do not press a key, Act 1 starts on its own.
		if _title_t > 10.0:
			_go_cavern()

	# Safety net: if any collision gap still lets the player out of the house,
	# put them back on the floor instead of ending the run.
	if player.global_position.y < -2.0 and state not in [S.SELECT, S.FALL, S.TITLE]:
		player.teleport(1.75, 0.1, 1.35, -1.9)
		_say("...the floor is still there. You are still here.", 2.5)

	# Beat 7 is handled by DialogueBox, which owns its own input while open.
	# The prologue must not also react to E here or every press would double.

	if state == S.MOM:
		_mom_timer -= delta
		_hud_clock.text = "FEB 30  12:00"
		if _mom_timer <= 0.0:
			_auto_push()  # they get pulled in with you either way
		elif Input.is_action_just_pressed("interact"):
			_do_push()

	if _shake > 0.0:
		_shake -= delta
		_cam.h_offset = randf_range(-1, 1) * _shake * 8.0
		_cam.v_offset = randf_range(-1, 1) * _shake * 8.0
	else:
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0


func _tick_clock_hud() -> void:
	if state == S.MOM:
		_hud_clock.text = "FEB 30  12:00"
	elif state in [S.FALL, S.TITLE]:
		_hud_clock.text = ""
	else:
		_hud_clock.text = "FEB 29  11:59"


func _flicker(_d: float) -> void:
	# streetlight breathes like a passing car. one light, zero cost.
	if _streetlight != null and state not in [S.FALL, S.TITLE]:
		_streetlight.light_energy = 0.5 + sin(Time.get_ticks_msec() * 0.0004) * 0.12


# ---------------------------------------------------------------- knocks -> door -> jumpscare -> talk

func _start_knocks() -> void:
	if _knock_done:
		return
	_knock_done = true
	state = S.KNOCK
	_knock_ready = false
	GameState.heard_knock = true
	Clock.set_time(11, 59)
	# The music box stops mid-phrase, and the house has four seconds of
	# nothing in it. That gap is the scare; docs/prologue.md Beat 4.
	AudioDirector.stop_music()
	AudioDirector.duck_ambience(0.6)
	_say("", 0.1)
	await get_tree().create_timer(4.0).timeout
	if state != S.KNOCK:
		return
	AudioDirector.un_duck_ambience(1.2)
	# The door is not flush. It is moving very slightly.
	_house_call("set_wardrobe_dread", true)
	AudioDirector.play_creak()
	_say("...shff. shff. shff.  (from the wardrobe)", 3.0)
	await get_tree().create_timer(3.2).timeout
	if state != S.KNOCK:
		return
	AudioDirector.play_dread()
	AudioDirector.play_knock(3, 0.3)
	_say("knock. knock. knock.   ...   knock. knock. knock.", 4.0)
	_knock_ready = true
	_prompt.text = "[E] open the wardrobe"
	player.look_at_point(Vector3(3.0, 1.3, 0.9))


func _house_call(method: String, arg: Variant) -> void:
	if _house != null and _house.has_method(method):
		_house.call(method, arg)


func _check_wardrobe_early() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	var ray := player.get_node_or_null("Head/Camera3D/InteractRay") as RayCast3D
	var looking_at_door := false
	if ray != null and ray.is_colliding():
		var n: Object = ray.get_collider()
		var nn: String = (n as Node).name if n is Node else ""
		if "Wardrobe" in nn or "wardrobe" in nn:
			looking_at_door = true
	var close := player.global_position.distance_to(Vector3(3.0, 0.0, 0.9)) < 2.4
	if close and (looking_at_door or state == S.KNOCK):
		_open_wardrobe()


func _open_wardrobe() -> void:
	state = S.DOOR_OPEN
	_prompt.text = ""
	_house_call("set_wardrobe_dread", false)
	AudioDirector.play_creak()
	# swing door open, toward the east wall so it never crosses the shot
	if _door != null:
		var tw := create_tween()
		tw.tween_property(_door, "rotation:y", 1.45, 0.7).set_trans(Tween.TRANS_QUAD)
	await get_tree().create_timer(0.55).timeout
	_jumpscare()
	await get_tree().create_timer(0.45).timeout
	_reveal_wren()


func _jumpscare() -> void:
	# JUMPSCARE (mild, fair-tell per docs/worlds.md rule 6):
	# 350ms freeze + loud down-pitched knock + red flash + shake. Then Wren.
	get_tree().paused = true
	AudioDirector.scare_hit()
	_flash.color = Color(0.85, 0.02, 0.02, 0.85)
	_shake = 0.5
	await get_tree().create_timer(0.35, true, false, true).timeout
	get_tree().paused = false
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.6)
	(wren as Node).call("scare_pose")


func _reveal_wren() -> void:
	(wren as Node).call("reveal")
	GameState.met_wren = true
	state = S.TALK
	player.can_move = false
	# Wren now stands in front of the wardrobe instead of inside its solid
	# mesh, where the player could hear them but never see them.
	# look at the face, not the chest; the hat then does not hide the eyes
	player.look_at_point(Vector3(3.0, 0.72, 1.15))
	_prompt.text = ""
	_run_node("start")


# ---------------------------------------------------------------- Beat 7
#
# The choice tree. docs/prologue.md Beat 7: every option converges on the
# same beat, and the point is the player trying to be kind to something
# they do not understand. There is no correct answer and nothing is scored.
#
# Format: speaker, lines (shown in order), then either another node via
# "next" (String) or a player choice ("prompt" + "options" + "next" Array).

const _DLG := {
	"start": {
		"speaker": "WREN",
		"lines": ["It's my birthday too.", "It's the 30th of February."],
		"prompt": "",
		"options": ["There's no 30th of February.", "What do you mean?",
			"Are you in my cupboard?", "Are you OK?"],
		"next": ["no30", "mean", "cupboard", "ok"],
	},
	"no30": {
		"speaker": "WREN",
		"lines": ["There is. It comes after the 29th.",
			"You just have to stay awake for it."],
		"prompt": "",
		"options": ["That's not how dates work.", "Are you OK?"],
		"next": ["dates", "ok"],
	},
	"dates": {
		"speaker": "WREN",
		"lines": ["Maybe not here.", "It's how they work where I'm from."],
		"prompt": "",
		"options": ["Are you in my cupboard?", "Are you OK?"],
		"next": ["cupboard", "ok"],
	},
	"mean": {
		"speaker": "WREN",
		"lines": ["The date. The one after the 29th.",
			"It's mine. It's the 30th of February."],
		"prompt": "",
		"options": ["It's my birthday.", "Don't you know your birthday?",
			"(say nothing)"],
		"next": ["share", "dontknow", "silence"],
	},
	"share": {
		"speaker": "WREN",
		"lines": ["Then we can share it.", "I don't mind sharing."],
		"prompt": "",
		"options": ["Are you in my cupboard?", "Are you OK?"],
		"next": ["cupboard", "ok"],
	},
	"dontknow": {
		"speaker": "WREN",
		"lines": ["I know the number.", "I just never got the day."],
		"prompt": "",
		"options": ["Why are you in my cupboard?", "Are you OK?"],
		"next": ["cupboard", "ok"],
	},
	"silence": {
		"speaker": "WREN",
		"lines": ["You can go back to bed.", "I'll wait in here."],
		"prompt": "",
		"options": ["Are you in my cupboard?", "Are you OK?"],
		"next": ["cupboard", "ok"],
	},
	"cupboard": {
		"speaker": "WREN",
		"lines": ["It's warm in here.", "Nobody looks in the cupboard."],
		"prompt": "",
		"options": ["You have a bed.", "Are you OK?"],
		"next": ["bed", "ok"],
	},
	"bed": {
		"speaker": "WREN",
		"lines": ["I don't want your bed.", "I want the day."],
		"prompt": "",
		"options": ["Are you OK?", "(say nothing)"],
		"next": ["ok", "silence2"],
	},
	"silence2": {
		"speaker": "WREN",
		"lines": ["That's alright.", "I'm good at waiting."],
		"next": "ok",
	},
	# No parent branch. The old "Do you want me to get mum?" option and its
	# sting are gone: the player never asks where Wren's parents are.
	"ok": {
		"speaker": "WREN",
		"lines": ["You're not going to leave?", "It's cold in here."],
		"prompt": "",
		"options": ["I'll stay.", "I won't leave you."],
		"next": ["stay", "promise"],
	},
	"stay": {
		"speaker": "WREN",
		"lines": ["...okay.", "Don't let them find me."],
		"next": "end",
	},
	"promise": {
		"speaker": "WREN",
		"lines": ["Promise?"],
		"prompt": "",
		"options": ["I promise.", "(say nothing)"],
		"next": ["end", "end2"],
	},
	"end2": {
		"speaker": "WREN",
		"lines": ["...okay."],
		"next": "end",
	},
	"end": {
		"speaker": "WREN",
		"lines": [],
	},
}


func _run_node(id: String) -> void:
	if not _DLG.has(id):
		_start_mom()
		return
	var n: Dictionary = _DLG[id]
	# Beat 7, "the player forgets their birthday": it happens by omission,
	# during the conversation, and the HUD readout just quietly stops.
	if id == "ok":
		Clock.forget_birthday()
	var lines: Array = n.get("lines", [])
	if not lines.is_empty():
		_dlg.show_lines(str(n.get("speaker", "WREN")), lines)
		await _dlg.line_finished
	if n.has("options"):
		_dlg.show_choice(str(n.get("speaker", "YOU")), str(n.get("prompt", "")), n["options"])
		var picked: int = await _dlg.option_chosen
		var nxt: Array = n.get("next", [])
		if picked < nxt.size() and str(nxt[picked]) != "":
			_run_node(str(nxt[picked]))
		else:
			_start_mom()
	elif n.has("next") and str(n["next"]) != "":
		_run_node(str(n["next"]))
	else:
		_start_mom()


## Used by tests/test_dialogue.gd. Every branch must land somewhere real.
func validate_dialogue_tree() -> Array:
	var errors: Array = []
	for id in _DLG.keys():
		var n: Dictionary = _DLG[id]
		if n.has("options"):
			var opts: Array = n["options"]
			var nxt: Array = n.get("next", [])
			if opts.size() != nxt.size():
				errors.append("%s: %d options but %d next" % [id, opts.size(), nxt.size()])
			for t in nxt:
				if str(t) != "" and not _DLG.has(str(t)):
					errors.append("%s -> missing node %s" % [id, str(t)])
		elif n.has("next") and str(n["next"]) != "" and not _DLG.has(str(n["next"])):
			errors.append("%s -> missing node %s" % [id, str(n["next"])])
	return errors


func _start_mom() -> void:
	state = S.MOM
	# The warm house goes out. Only the streetlight and the line under her
	# door are left, and the music box is flat now. docs/prologue.md Beat 5.
	_house_call("set_midnight", true)
	_house_call("set_wardrobe_dread", false)
	AudioDirector.play_lock()
	AudioDirector.play_musicbox_30th()
	_say('MUM (downstairs): "Is everything alright? I thought I heard something."', 4.0)
	_prompt.text = "[E] PUSH THEM IN — hide them!  (4 seconds)"
	_mom_timer = 6.0
	Clock.roll_to_30th()


func _do_push() -> void:
	if state != S.MOM:
		return
	GameState.pushed = true
	_say('"Please don\'t," they say, one more time.', 2.0)
	await get_tree().create_timer(1.2).timeout
	_start_fall()


func _auto_push() -> void:
	# out of time: same outcome, no punishment. the game never scores this.
	_do_push()


# ---------------------------------------------------------------- the fall (Part 1 ending)

func _start_fall() -> void:
	state = S.FALL
	GameState.falling = true
	_prompt.text = ""
	_sub.text = ""
	AudioDirector.stop_ambience(0.8)
	player.can_move = false
	player.set_physics_process(false)
	_tunnel.visible = true
	_fade_to(0.0, 0.2)
	# camera dives into the wardrobe: no cut, it goes in with them.
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cam, "fov", 95.0, 3.2).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(player, "global_position", Vector3(3.0, 1.0, -4.0), 3.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	player.look_at_point(Vector3(3.0, 0.8, -10.0))
	_shake = 3.0
	await get_tree().create_timer(3.4).timeout
	_shake = 0.0
	_fade_to(1.0, 1.2)
	await get_tree().create_timer(1.4).timeout
	_show_title()


func _show_title() -> void:
	state = S.TITLE
	GameState.finished = true
	# Black card, not a shot of the tunnel. The backdrop sits under the title
	# and over the world, so nothing pokes through the type.
	_title_bg.visible = true
	_title.visible = true
	_title_sub.text = "ACT I — THE CAVERN"
	_hud_clock.text = ""
	_title_t = 0.0
	_prompt.text = "[ENTER] continue        [R] replay"
	AudioDirector.play_bad_cheer(true)
	_say("", 0.1)
	_fade_to(0.0, 2.5)
	_title_label.text = "FEBRUARY 30th"
	# pulse the title like a bad VHS
	var tw := create_tween().set_loops()
	tw.tween_property(_title_label, "modulate:a", 0.55, 0.9)
	tw.tween_property(_title_label, "modulate:a", 1.0, 0.9)


func _go_cavern() -> void:
	if _going:
		return
	_going = true
	get_tree().change_scene_to_file("res://scenes/cavern.tscn")


func _unhandled_input(event: InputEvent) -> void:
	# Click to recapture the mouse after alt-tab or a menu. This is the
	# failure that made the camera look broken in playtest.
	if event is InputEventMouseButton and event.is_pressed() \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
				and not _mouse_free and not (_pause != null and _pause.is_open()) \
				and not (_dlg != null and _dlg.is_choosing()) \
				and state not in [S.SELECT, S.TITLE]:
			player.capture_mouse()
			get_viewport().set_input_as_handled()
			return

	if state != S.TITLE:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var ke := event as InputEventKey
		var k: int = ke.physical_keycode
		if k == 0:
			k = ke.keycode
		match k:
			KEY_R:
				get_tree().reload_current_scene()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E, KEY_N:
				_go_cavern()
	elif event is InputEventMouseButton and event.is_pressed():
		_go_cavern()


func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_IN:
		return
	if state in [S.SELECT, S.TITLE] or _mouse_free:
		return
	if _pause != null and _pause.is_open():
		return
	if _dlg != null and _dlg.is_choosing():
		return
	player.capture_mouse()
