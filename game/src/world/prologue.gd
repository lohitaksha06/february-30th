extends Node3D
## Prologue Part 1 director: wake in bed -> knocks -> wardrobe -> Wren -> push -> FALL.
## docs/prologue.md beats 1,4,6,8,9 compressed to ~6 minutes. No enemies.
## Everything is script-driven. Player only walks / looks / presses E.

enum S { SELECT, LYING, SITUP, EXPLORE, KNOCK, DOOR_OPEN, TALK, MOM, FALL, TITLE }

var state: int = S.SELECT
var _t := 0.0
var _knock_done := false
var _mom_timer := 0.0
var _push_window := 0.0

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
var _title_label: Label
var _choice_box: VBoxContainer
var _dlg: DialogueBox

var _cam: Camera3D
var _door: MeshInstance3D
var _streetlight: DirectionalLight3D
var _tunnel: Node3D
var _shake := 0.0


func _ready() -> void:
	GameState.reset_prologue()
	Clock.set_time(11, 48)
	_cam = player.get_node("Head/Camera3D") as Camera3D
	_find_door()
	_find_streetlight()
	_build_ui()
	_build_tunnel()
	_start_select()


# ---------------------------------------------------------------- setup

func _find_door() -> void:
	_door = get_node_or_null("House/WardrobeDoor") as MeshInstance3D
	if _door == null:
		_door = _search(get_node("House"), "WardrobeDoor") as MeshInstance3D


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
	_hud_clock.text = "FEB 29  11:48"
	_hud_clock.add_theme_font_size_override("font_size", 13)
	_hud_clock.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 0.85))
	_hud_clock.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud_clock.position = Vector2(12, 8)
	_ui.add_child(_hud_clock)

	_sub = Label.new()
	_sub.name = "Subtitle"
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
	_prompt.name = "Prompt"
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-300, -34)
	_prompt.size = Vector2(600, 24)
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
	_choice_box.position = Vector2(-90, -40)
	_choice_box.add_theme_constant_override("separation", 10)
	_ui.add_child(_choice_box)

	# title card (hidden)
	_title = CenterContainer.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.visible = false
	_ui.add_child(_title)
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 42)
	_title_label.add_theme_color_override("font_color", Color(0.88, 0.10, 0.10))
	_title_label.text = "FEBRUARY 30th"
	_title.add_child(_title_label)

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
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, dur)


# ---------------------------------------------------------------- beats

func _start_select() -> void:
	state = S.SELECT
	player.can_move = false
	_fade.color.a = 1.0
	_fade_to(1.0, 0.01)
	_say("FEBRUARY 29th.", 2.5)
	for c in _choice_box.get_children():
		c.queue_free()
	var l := Label.new()
	l.text = "who are you?"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_box.add_child(l)
	for g in ["boy", "girl"]:
		var b := Button.new()
		b.text = g.to_upper()
		b.custom_minimum_size = Vector2(180, 36)
		b.pressed.connect(_on_pick.bind(g))
		_choice_box.add_child(b)
	_fade_to(0.0, 1.5)


func _on_pick(g: String) -> void:
	if state != S.SELECT:
		return
	GameState.gender = g
	for c in _choice_box.get_children():
		c.queue_free()
	_choice_box.visible = false
	_start_lying()


func _start_lying() -> void:
	state = S.LYING
	# lying in bed: eye at pillow height, staring at ceiling
	player.teleport(0.85, 0.78, 2.55, 2.6)
	player.can_move = false
	(player.get_node("Head") as Node3D).rotation.x = -0.9  # looking up
	_fade_to(0.0, 2.0)
	_say("11:48 PM. The streetlight moves across the ceiling.", 4.0)
	_prompt.text = "[E] sit up"
	await get_tree().create_timer(1.0).timeout
	Clock.set_time(11, 48)


func _sit_up() -> void:
	state = S.SITUP
	_prompt.text = ""
	GameState.sat_up = true
	player.teleport(1.75, 0.1, 2.1, -1.9)
	(player.get_node("Head") as Node3D).rotation.x = 0.0
	player.can_move = true
	AudioDirector.play_musicbox_real()
	_say("Cake in the living room. Eleven candles. Go look — then come back to bed.", 5.0)
	clock3d.text = "11:48"
	state = S.EXPLORE
	_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	_tick_clock_hud()
	_flicker(delta)

	if state == S.LYING and Input.is_action_just_pressed("interact"):
		_sit_up()

	if state == S.EXPLORE:
		_prompt.text = "find the wardrobe  [WASD walk · mouse look · F torch]"
		# after ~30s (or player near wardrobe) -> knocks
		var near := player.global_position.distance_to(Vector3(3.0, 0.0, 0.8)) < 2.2
		if _t > 30.0 or (_t > 8.0 and near):
			_start_knocks()
		_check_wardrobe_early()

	if state == S.KNOCK:
		_check_wardrobe_early()

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
	if state in [S.SELECT, S.LYING]:
		_hud_clock.text = "FEB 29  11:48"
	elif state == S.EXPLORE:
		_hud_clock.text = "FEB 29  11:5%d" % int(min(_t / 10.0, 2.0))
	elif state == S.KNOCK:
		_hud_clock.text = "FEB 29  11:59"
	elif state in [S.DOOR_OPEN, S.TALK]:
		_hud_clock.text = "FEB 29  11:59"
	elif state == S.MOM:
		_hud_clock.text = "FEB 30  12:00"


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
	GameState.heard_knock = true
	Clock.set_time(11, 59)
	AudioDirector.stop_music()
	_say("...shff. shff. shff.  (from the wardrobe)", 3.0)
	await get_tree().create_timer(3.2).timeout
	if state != S.KNOCK:
		return
	AudioDirector.play_knock(3, 0.3)
	_say("knock. knock. knock.   ...   knock. knock. knock.", 4.0)
	_prompt.text = "[E] open the wardrobe"
	player.look_at_point(Vector3(3.0, 1.3, 0.55))


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
	# swing door open
	if _door != null:
		var tw := create_tween()
		tw.tween_property(_door, "rotation:y", -1.9, 0.7).set_trans(Tween.TRANS_QUAD)
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
	player.look_at_point(Vector3(3.0, 0.55, 0.55))
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
		"lines": ["It's my birthday too.", "It's the thirtieth."],
		"prompt": "",
		"options": ["There's no thirtieth.", "What do you mean?",
			"Are you in my cupboard?", "Are you OK?"],
		"next": ["no30", "mean", "cupboard", "ok"],
	},
	"no30": {
		"speaker": "WREN",
		"lines": ["There is. It comes after the twenty-ninth.",
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
		"lines": ["The date. The one after the twenty-ninth.",
			"It's mine. It's the thirtieth."],
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
	"ok": {
		"speaker": "WREN",
		"lines": ["No.", "Please don't get her."],
		"prompt": "",
		"options": ["Do you want me to get mum?", "I won't get her."],
		"next": ["mumsting", "promise"],
	},
	"mumsting": {
		"speaker": "WREN",
		"lines": ["No.", "Please don't get her.", "Please don't."],
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
	AudioDirector.play_lock()
	_say('MUM (downstairs): "Is everything alright? I thought I heard something."', 4.0)
	_prompt.text = "[E] PUSH THEM IN — hide them!  (4 seconds)"
	_mom_timer = 6.0
	Clock.roll_to_30th()
	AudioDirector.play_musicbox_30th()


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
	_title.visible = true
	_hud_clock.text = ""
	_prompt.text = "[R] watch again    [N] descend"
	_say("a crowd of children cheering, slightly out of time. far away.", 6.0)
	_fade_to(0.0, 2.5)
	_title_label.text = "FEBRUARY 30th"
	# pulse the title like a bad VHS
	var tw := create_tween().set_loops()
	tw.tween_property(_title_label, "modulate:a", 0.55, 0.9)
	tw.tween_property(_title_label, "modulate:a", 1.0, 0.9)


func _unhandled_input(event: InputEvent) -> void:
	if state == S.TITLE and event is InputEventKey and event.is_pressed():
		match (event as InputEventKey).physical_keycode:
			KEY_R:
				get_tree().reload_current_scene()
			KEY_N:
				get_tree().change_scene_to_file("res://scenes/cavern.tscn")
