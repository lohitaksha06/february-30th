extends Node3D
## The morning. You come up through the cupboard and the house is ordinary.
## No enemies, no stamina, no chase. This is the payoff room: warm light,
## mum downstairs, and one open cupboard door you do not close.
##
## docs/worlds.md "The morning". Short on purpose -- the game has already
## said what it needed to say at the door.

enum S { MORNING, END }

@onready var player: Player = $Player

var hud: JourneyHUD
var state: int = S.MORNING
var _t := 0.0
var _said_mum := false
var _wardrobe_done := false
var _final := false

const WARDROBE := Vector3(0, 0, 2.6)
const DOOR := Vector3(0, 0, -5.0)

var _prompt_near := ""


func _ready() -> void:
	_build_room()
	hud = JourneyHUD.new()
	add_child(hud)
	hud.setup(false)
	hud.fade.color.a = 1.0
	hud.fade_to(0.0, 2.4)
	hud.objective("morning  ·  go downstairs")
	hud.say("FEBRUARY 29th. 8:12 in the morning.")
	hud.say("You came up through the cupboard. Your room. Your bed.")
	player.teleport(0.0, 0.1, 1.4, 0.0)
	player.can_move = true
	player.stamina_enabled = false
	player.look_at_point(Vector3(0, 1.1, -3.0))
	AudioDirector.play_musicbox_real()
	AudioDirector.restore_music_volume()


func _process(delta: float) -> void:
	_t += delta
	if state != S.MORNING:
		return

	if not _said_mum and _t > 4.5:
		_said_mum = true
		hud.say('MUM (downstairs): "Happy birthday, love. Pancakes!"')
		hud.say("Her radio is on. She is singing along to it, badly.")

	# The one interactive object in the room, and it is the way you came in.
	var pp: Vector3 = player.global_position
	pp.y = 0.0
	if pp.distance_to(WARDROBE) < 2.4:
		if not _wardrobe_done:
			_prompt_near = "[E] look in the cupboard"
			hud.prompt(_prompt_near)
		else:
			hud.prompt("")
		if not _wardrobe_done and Input.is_action_just_pressed("interact"):
			_wardrobe_done = true
			hud.prompt("")
			hud.say("It smells like rain in there. A party hat. Too small.")
			hud.say("You leave the door open.")
			hud.objective("go downstairs")
		return

	if pp.distance_to(DOOR) < 2.0:
		hud.prompt("[E] go downstairs")
		if Input.is_action_just_pressed("interact"):
			_go_downstairs()
		return

	hud.prompt("")


func _go_downstairs() -> void:
	if state != S.MORNING:
		return
	state = S.END
	player.can_move = false
	player.release_mouse()
	AudioDirector.stop_music()
	hud.fade_to(0.55, 1.2)
	await get_tree().create_timer(1.4).timeout
	hud.end_card("FEBRUARY 29th", "for Wren\n\n[E] play again")
	_final = true
	get_tree().create_timer(0.1).timeout  # let the card lay out before input
	hud.fade_to(0.0, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if not _final:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var k: int = (event as InputEventKey).physical_keycode
		if k == KEY_E or k == KEY_ENTER or k == KEY_R:
			get_tree().change_scene_to_file("res://scenes/prologue.tscn")


# ---------------------------------------------------------------- room

func _mat(c: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(pos: Vector3, size: Vector3, col: Color, collide := true, unshaded := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col, unshaded)
	mi.position = pos
	add_child(mi)
	if collide and size.y > 0.25:
		var body := StaticBody3D.new()
		body.position = pos
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		add_child(body)
	return mi


func _build_room() -> void:
	var wall := Color(0.56, 0.52, 0.46)
	var wain := Color(0.42, 0.38, 0.34)
	# floor / ceiling / walls
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(7, 8)
	floor_mi.mesh = pm
	floor_mi.position = Vector3(0, 0, -1)
	floor_mi.material_override = _mat(Color(0.34, 0.24, 0.17))
	add_child(floor_mi)
	# invisible-ish collider slab under the plane
	_box(Vector3(0, -0.26, -1), Vector3(7.0, 0.5, 8.0), Color(0.20, 0.14, 0.10))
	_box(Vector3(0, 1.5, -5.1), Vector3(7.2, 3.1, 0.3), wall)
	_box(Vector3(0, 1.5, 3.1), Vector3(7.2, 3.1, 0.3), wall)
	_box(Vector3(-3.5, 1.5, -1), Vector3(0.3, 3.1, 8.2), wall)
	_box(Vector3(3.5, 1.5, -1), Vector3(0.3, 3.1, 8.2), wall)
	_box(Vector3(0, 3.15, -1), Vector3(7.2, 0.3, 8.2), Color(0.62, 0.59, 0.53))
	# skirting
	_box(Vector3(0, 0.14, -4.92), Vector3(7.0, 0.28, 0.08), wain, false)
	_box(Vector3(-3.38, 0.14, -1), Vector3(0.08, 0.28, 8.0), wain, false)
	_box(Vector3(3.38, 0.14, -1), Vector3(0.08, 0.28, 8.0), wain, false)
	# rug
	var rug := MeshInstance3D.new()
	var rq := PlaneMesh.new()
	rq.size = Vector2(3.4, 2.4)
	rug.mesh = rq
	rug.position = Vector3(0, 0.02, -2.0)
	rug.material_override = _mat(Color(0.28, 0.16, 0.18))
	add_child(rug)

	_bed()
	_wardrobe()
	_desk()
	_window()
	_door()
	_posters()
	_lights()


func _bed() -> void:
	_box(Vector3(-1.9, 0.28, -3.1), Vector3(2.2, 0.5, 3.0), Color(0.28, 0.20, 0.15))
	_box(Vector3(-1.9, 0.58, -3.1), Vector3(2.1, 0.22, 2.9), Color(0.72, 0.70, 0.66))
	_box(Vector3(-1.9, 0.71, -3.1), Vector3(2.0, 0.14, 2.7), Color(0.36, 0.44, 0.58))
	_box(Vector3(-1.9, 0.74, -4.05), Vector3(1.7, 0.16, 0.55), Color(0.82, 0.80, 0.74))
	_box(Vector3(-1.9, 0.88, -1.8), Vector3(2.0, 0.18, 0.55), Color(0.30, 0.38, 0.52))
	# bedside table + clock
	_box(Vector3(-0.45, 0.3, -4.3), Vector3(0.7, 0.6, 0.7), Color(0.30, 0.22, 0.16))
	var lbl := Label3D.new()
	lbl.text = "08:12"
	lbl.font_size = 42
	lbl.pixel_size = 0.0035
	lbl.modulate = Color(0.95, 0.25, 0.20)
	lbl.position = Vector3(-0.45, 0.66, -4.3)
	lbl.rotation_degrees = Vector3(0, 0, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.no_depth_test = false
	add_child(lbl)


func _wardrobe() -> void:
	var wood := Color(0.30, 0.21, 0.15)
	var dark := Color(0.06, 0.05, 0.05)
	_box(Vector3(0, 1.1, 2.86), Vector3(2.2, 2.2, 0.12), wood)
	_box(Vector3(-1.05, 1.1, 2.55), Vector3(0.12, 2.2, 0.65), wood)
	_box(Vector3(1.05, 1.1, 2.55), Vector3(0.12, 2.2, 0.65), wood)
	_box(Vector3(0, 2.24, 2.55), Vector3(2.2, 0.12, 0.65), wood)
	_box(Vector3(0, 0.06, 2.55), Vector3(2.2, 0.12, 0.65), wood, false)
	# interior dark
	_box(Vector3(0, 1.08, 2.78), Vector3(1.9, 2.0, 0.04), dark, false, true)
	# open doors, angled out into the room
	var dl := _box(Vector3(-0.98, 1.1, 2.25), Vector3(0.08, 2.12, 0.95), wood, false)
	dl.rotation_degrees = Vector3(0, -52, 0)
	var dr := _box(Vector3(0.98, 1.1, 2.25), Vector3(0.08, 2.12, 0.95), wood, false)
	dr.rotation_degrees = Vector3(0, 52, 0)
	# the party hat on the floor of the cupboard. Too small, like Wren's.
	var hat := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.07
	cone.height = 0.13
	hat.mesh = cone
	hat.position = Vector3(0.25, 0.15, 2.55)
	hat.rotation_degrees = Vector3(0, 0, 12)
	hat.material_override = _mat(Color(0.75, 0.28, 0.30))
	add_child(hat)


func _desk() -> void:
	_box(Vector3(2.6, 0.72, -3.4), Vector3(1.5, 0.1, 0.8), Color(0.33, 0.24, 0.17))
	for x in [-0.65, 0.65]:
		_box(Vector3(2.6 + x, 0.36, -3.4), Vector3(0.1, 0.72, 0.7), Color(0.28, 0.20, 0.15))
	_box(Vector3(2.6, 0.86, -3.75), Vector3(0.5, 0.18, 0.3), Color(0.16, 0.16, 0.18), false)
	_box(Vector3(2.6, 0.92, -3.62), Vector3(0.36, 0.02, 0.22), Color(0.7, 0.85, 0.95), false, true)
	# chair
	_box(Vector3(2.5, 0.42, -2.6), Vector3(0.55, 0.08, 0.55), Color(0.30, 0.22, 0.16), false)
	_box(Vector3(2.5, 0.8, -2.35), Vector3(0.55, 0.7, 0.08), Color(0.30, 0.22, 0.16), false)


func _window() -> void:
	# right wall, morning outside
	var sun := Color(1.0, 0.93, 0.78)
	_box(Vector3(3.34, 1.95, -1.4), Vector3(0.08, 1.7, 2.0), sun, false, true)
	_box(Vector3(3.30, 1.95, -1.4), Vector3(0.06, 1.8, 0.08), Color(0.45, 0.40, 0.34), false)
	_box(Vector3(3.30, 1.95, -1.4), Vector3(0.06, 0.08, 2.1), Color(0.45, 0.40, 0.34), false)
	# curtains
	_box(Vector3(3.22, 1.95, -2.55), Vector3(0.10, 1.9, 0.5), Color(0.72, 0.66, 0.55), false)
	_box(Vector3(3.22, 1.95, -0.25), Vector3(0.10, 1.9, 0.5), Color(0.72, 0.66, 0.55), false)


func _door() -> void:
	_box(Vector3(0, 1.15, -4.94), Vector3(1.1, 2.3, 0.10), Color(0.40, 0.30, 0.21))
	_box(Vector3(0, 1.15, -4.90), Vector3(1.3, 2.5, 0.05), Color(0.52, 0.48, 0.42), false)
	# brass knob
	_box(Vector3(0.38, 1.05, -4.86), Vector3(0.08, 0.08, 0.06), Color(0.72, 0.62, 0.34), false)
	# a strip of hallway light under it
	_box(Vector3(0, 0.02, -4.88), Vector3(1.0, 0.03, 0.12), Color(1.0, 0.90, 0.70), false, true)


func _posters() -> void:
	_box(Vector3(-3.34, 2.0, -2.2), Vector3(0.03, 0.9, 0.65), Color(0.20, 0.30, 0.42), false, true)
	_box(Vector3(-3.32, 2.0, -2.2), Vector3(0.02, 0.75, 0.52), Color(0.60, 0.72, 0.85), false, true)
	_box(Vector3(-3.34, 1.6, 0.2), Vector3(0.03, 0.6, 0.45), Color(0.55, 0.45, 0.28), false, true)
	# calendar with the last week torn off
	_box(Vector3(1.2, 1.9, -4.92), Vector3(0.55, 0.7, 0.02), Color(0.82, 0.80, 0.74), false, true)
	_box(Vector3(1.2, 2.12, -4.90), Vector3(0.42, 0.18, 0.01), Color(0.72, 0.18, 0.16), false, true)


func _lights() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.20, 0.19, 0.20)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.56, 0.46)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.50, 0.44)
	env.fog_density = 0.01
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.92, 0.76)
	sun.light_energy = 0.85
	sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-38, 118, 0)
	add_child(sun)

	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.82, 0.58)
	lamp.light_energy = 0.8
	lamp.omni_range = 6.0
	lamp.shadow_enabled = false
	lamp.position = Vector3(2.6, 1.3, -3.6)
	add_child(lamp)
