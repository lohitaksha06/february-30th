extends Node3D
## The birthday party. Evening, Feb 29th.
##
## He got home. Mum got the day right. Two plates, two hats, and an empty
## chair. He does not feel like celebrating: at the door Wren told him that
## spending time together was the best birthday they ever had. He understands
## now that it was a lie -- a kind one, said so he would go home and have his.
##
## No enemies, no stamina, no chase. The last room in the game is a table.

enum S { PARTY, FINALE, END }

@onready var player: Player = $Player

var hud: JourneyHUD
var dlg: DialogueBox
var mum: Node3D
var state: int = S.PARTY
var _t := 0.0
var _said_two := false
var _said_mum := false
var _final := false
var _candle_light: OmniLight3D
var _mum_head: MeshInstance3D

const CAKE := Vector3(0, 0.9, -0.7)
const MUM_POS := Vector3(-2.0, 0, -2.1)
const CAKE_REACH := 2.4


func _ready() -> void:
	_build_room()
	_build_mum()

	hud = JourneyHUD.new()
	add_child(hud)
	hud.setup(false)
	dlg = DialogueBox.new()
	hud.add_child(dlg)

	hud.fade.color.a = 1.0
	hud.fade_to(0.0, 2.4)
	hud.objective("it's your birthday")
	hud.say("FEBRUARY 29th. 6:40 in the evening.")
	hud.say("You came up through the cupboard this morning.")
	hud.say("You don't remember the rest of the day.")

	player.teleport(0.0, 0.1, 3.0, 0.0)
	player.can_move = true
	player.stamina_enabled = false
	player.look_at_point(CAKE + Vector3(0, 0.45, 0))
	AudioDirector.play_musicbox_real()
	AudioDirector.restore_music_volume()


func _process(delta: float) -> void:
	_t += delta
	if _candle_light != null:
		# candles breathe. One light, no shadows, free at 320x180.
		_candle_light.light_energy = 0.55 + sin(_t * 9.0) * 0.08 + sin(_t * 23.0) * 0.03
	if _mum_head != null:
		_mum_head.rotation.z = sin(_t * 0.8) * 0.02

	if state != S.PARTY:
		return

	# Mum fills the silence. The kid does not.
	if not _said_two and _t > 7.0:
		_said_two = true
		hud.say("Two plates. Two hats. Mum doesn't know why she set the second one.")
	if not _said_mum and _t > 11.0:
		_said_mum = true
		hud.say("MUM: There you are. Happy birthday, love.")
		hud.say("MUM: Sit down. I'll cut it.")
		hud.objective("the candles are waiting")

	var pp: Vector3 = player.global_position
	if pp.distance_to(CAKE) < CAKE_REACH:
		hud.prompt("[E] the cake")
		if Input.is_action_just_pressed("interact"):
			_start_cake()
	else:
		hud.prompt("")


# ---------------------------------------------------------------- the last scene

func _start_cake() -> void:
	if state != S.PARTY:
		return
	state = S.FINALE
	player.can_move = false
	player.set_process_unhandled_input(false)  # hold him at the table
	player.look_at_point(CAKE + Vector3(0, 0.2, 0))
	hud.prompt("")
	hud.objective("")
	hud.clear_say()

	dlg.show_choice("YOU", "You don't feel like celebrating.",
		["Blow out the candles.", "Leave them burning."])
	var picked: int = await dlg.option_chosen
	if picked == 0:
		dlg.show_lines("YOU", ["You blow them out. One for you. One for the empty chair."])
	else:
		dlg.show_lines("YOU", ["You let them burn. Mum doesn't ask why."])
	await dlg.line_finished

	# The realization, in his words. Wren lied so he would go home.
	dlg.show_lines("YOU", [
		"Two plates. Two hats. The chair opposite you is empty.",
		"Wren said spending time with you was the best birthday they ever had.",
		"You know now that it was a lie. They said it so you'd go home and have yours.",
		"Most people get to enjoy their life. Wren didn't get to enjoy theirs.",
		"You don't feel like celebrating. But you sit down anyway.",
	])
	await dlg.line_finished

	# Mum tries. He lets her.
	dlg.show_lines("MUM", [
		"I set two places. I don't know why. Silly, isn't it?",
		"Eat something, love. Please.",
	])
	await dlg.line_finished
	dlg.show_lines("YOU", ["...Okay."])
	await dlg.line_finished

	_finish_ending()


func _finish_ending() -> void:
	state = S.END
	player.release_mouse()
	AudioDirector.stop_music()
	hud.clear_say()
	hud.prompt("")
	hud.objective("")
	hud.fade_to(0.62, 1.4)
	await get_tree().create_timer(1.6).timeout
	hud.end_card("FEBRUARY 29th", "for Wren\n\n[E] play again")
	_final = true


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


## Part without collision, local to a parent. Used for Mum and table dressing.
func _part(parent: Node3D, pos: Vector3, size: Vector3, col: Color, unshaded := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col, unshaded)
	mi.position = pos
	parent.add_child(mi)
	return mi


## Invisible solid box. The tablecloth and seats are too thin for _box's
## collider rule, so furniture gets its own blocker.
func _collider(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	add_child(body)


func _build_room() -> void:
	var wall := Color(0.54, 0.46, 0.38)
	var wain := Color(0.34, 0.27, 0.22)
	# floor / ceiling / walls
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 10)
	floor_mi.mesh = pm
	floor_mi.position = Vector3(0, 0, 0)
	floor_mi.material_override = _mat(Color(0.34, 0.23, 0.15))
	add_child(floor_mi)
	_box(Vector3(0, -0.26, 0), Vector3(8.0, 0.5, 10.0), Color(0.20, 0.13, 0.09))
	_box(Vector3(0, 1.5, -5.1), Vector3(8.4, 3.2, 0.3), wall)
	_box(Vector3(0, 1.5, 5.1), Vector3(8.4, 3.2, 0.3), wall)
	_box(Vector3(-4.1, 1.5, 0), Vector3(0.3, 3.2, 10.2), wall)
	_box(Vector3(4.1, 1.5, 0), Vector3(0.3, 3.2, 10.2), wall)
	_box(Vector3(0, 3.15, 0), Vector3(8.4, 0.3, 10.2), Color(0.60, 0.54, 0.46))
	# wainscot
	_box(Vector3(0, 0.55, -4.92), Vector3(8.0, 1.1, 0.08), wain, false)
	_box(Vector3(-3.92, 0.55, 0), Vector3(0.08, 1.1, 10.0), wain, false)
	_box(Vector3(3.92, 0.55, 0), Vector3(0.08, 1.1, 10.0), wain, false)

	_window()
	_doorway()
	_kitchen()
	_table()
	_banner()
	_balloons()
	_lights()


func _window() -> void:
	# dusk outside, left wall
	var dusk := Color(0.78, 0.48, 0.42)
	_box(Vector3(-3.98, 1.85, -1.6), Vector3(0.06, 1.5, 2.3), dusk, false, true)
	_box(Vector3(-3.94, 1.85, -1.6), Vector3(0.05, 1.6, 0.10), Color(0.36, 0.28, 0.22), false)
	_box(Vector3(-3.94, 1.85, -1.6), Vector3(0.05, 0.10, 2.4), Color(0.36, 0.28, 0.22), false)
	# curtains, half-drawn
	_box(Vector3(-3.88, 1.85, -2.9), Vector3(0.08, 1.9, 0.55), Color(0.62, 0.48, 0.36), false)
	_box(Vector3(-3.88, 1.85, -0.3), Vector3(0.08, 1.9, 0.55), Color(0.62, 0.48, 0.36), false)
	# sill
	_box(Vector3(-3.86, 1.05, -1.6), Vector3(0.18, 0.08, 2.5), Color(0.44, 0.34, 0.26), false)


func _doorway() -> void:
	# the stairs you came up. Dark, but not a threat. Not any more.
	_box(Vector3(0, 1.3, 4.94), Vector3(1.3, 2.6, 0.12), Color(0.10, 0.08, 0.08), false)
	_box(Vector3(-0.72, 1.35, 4.9), Vector3(0.12, 2.7, 0.2), Color(0.30, 0.22, 0.16), false)
	_box(Vector3(0.72, 1.35, 4.9), Vector3(0.12, 2.7, 0.2), Color(0.30, 0.22, 0.16), false)
	_box(Vector3(0, 2.72, 4.9), Vector3(1.6, 0.12, 0.2), Color(0.30, 0.22, 0.16), false)


func _kitchen() -> void:
	var cabinet := Color(0.40, 0.33, 0.25)
	var counter := Color(0.60, 0.56, 0.48)
	# counter along the back wall
	_box(Vector3(-1.6, 0.45, -4.45), Vector3(5.0, 0.9, 0.9), cabinet)
	_box(Vector3(-1.6, 0.92, -4.45), Vector3(5.2, 0.08, 1.0), counter)
	# sink
	_box(Vector3(-1.2, 0.94, -4.42), Vector3(0.7, 0.03, 0.45), Color(0.62, 0.64, 0.64), false, true)
	_box(Vector3(-1.2, 1.12, -4.62), Vector3(0.06, 0.35, 0.06), Color(0.55, 0.55, 0.52), false)
	# upper cabinets
	_box(Vector3(-1.6, 2.2, -4.7), Vector3(5.0, 0.8, 0.5), cabinet)
	# fridge
	_box(Vector3(2.2, 1.0, -4.4), Vector3(1.0, 2.0, 0.8), Color(0.72, 0.70, 0.66))
	_box(Vector3(2.2, 1.35, -3.98), Vector3(0.06, 0.25, 0.05), Color(0.30, 0.30, 0.30), false)
	# a dish towel
	_box(Vector3(-1.2, 0.78, -3.96), Vector3(0.32, 0.35, 0.02), Color(0.62, 0.30, 0.28), false)


func _table() -> void:
	var cloth := Color(0.80, 0.75, 0.64)
	var wood := Color(0.34, 0.24, 0.16)
	# table
	_box(Vector3(0, 0.74, -0.7), Vector3(2.2, 0.10, 1.8), wood)
	_box(Vector3(0, 0.80, -0.7), Vector3(2.3, 0.04, 1.9), cloth, false)
	_collider(Vector3(0, 0.42, -0.7), Vector3(2.2, 0.82, 1.8))
	for x in [-0.9, 0.9]:
		for z in [-1.4, 0.0]:
			_box(Vector3(x, 0.37, z), Vector3(0.10, 0.74, 0.10), wood, false)
	# one empty chair, pulled out at the right. The player stands.
	_chair(Vector3(1.55, 0, -0.7), -0.24)
	# plates: yours on the left, the second place at the right end. Both visible.
	_plate(Vector3(-0.55, 0.85, 0.05))
	_plate(Vector3(0.75, 0.85, -0.70))
	# two hats, one on each plate. The second is the wrong size.
	_hat(Vector3(-0.53, 0.89, 0.07), Color(0.68, 0.22, 0.24), 0.0)
	_hat(Vector3(0.73, 0.89, -0.68), Color(0.26, 0.34, 0.62), 14.0)
	_cake()


func _chair(p: Vector3, back_z: float) -> void:
	var wood := Color(0.50, 0.34, 0.21)
	_collider(p + Vector3(0, 0.6, 0), Vector3(0.55, 1.2, 0.55))
	_box(p + Vector3(0, 0.45, 0), Vector3(0.5, 0.08, 0.5), wood, false)
	_box(p + Vector3(0, 0.50, 0), Vector3(0.42, 0.06, 0.42), Color(0.44, 0.18, 0.16), false)
	_box(p + Vector3(0, 0.82, back_z), Vector3(0.5, 0.68, 0.08), wood, false)
	for x in [-0.2, 0.2]:
		for z in [-0.2, 0.2]:
			_box(p + Vector3(x, 0.22, z), Vector3(0.06, 0.44, 0.06), Color(0.36, 0.24, 0.15), false)


func _plate(p: Vector3) -> void:
	var plate := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.24
	cm.bottom_radius = 0.20
	cm.height = 0.03
	cm.radial_segments = 12
	plate.mesh = cm
	plate.position = p
	plate.material_override = _mat(Color(0.88, 0.86, 0.80), true)
	add_child(plate)


func _hat(p: Vector3, col: Color, tilt: float) -> void:
	var hat := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.12
	cone.height = 0.30
	cone.radial_segments = 8
	hat.mesh = cone
	hat.position = p + Vector3(0, 0.15, 0)
	hat.rotation_degrees = Vector3(tilt, 0, -tilt * 0.5)
	hat.material_override = _mat(col)
	add_child(hat)
	# elastic string, because party hats always have one
	_box(p + Vector3(0, 0.04, 0.02), Vector3(0.01, 0.01, 0.18), Color(0.75, 0.70, 0.60), false)


func _cake() -> void:
	var plate := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.42
	pm.bottom_radius = 0.38
	pm.height = 0.04
	pm.radial_segments = 16
	plate.mesh = pm
	plate.position = CAKE + Vector3(0, -0.03, 0)
	plate.material_override = _mat(Color(0.78, 0.76, 0.70), true)
	add_child(plate)

	var body := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.34
	bm.bottom_radius = 0.36
	bm.height = 0.22
	bm.radial_segments = 16
	body.mesh = bm
	body.position = CAKE
	body.material_override = _mat(Color(0.62, 0.38, 0.30))
	add_child(body)

	var icing := MeshInstance3D.new()
	var im := CylinderMesh.new()
	im.top_radius = 0.35
	im.bottom_radius = 0.35
	im.height = 0.04
	im.radial_segments = 16
	icing.mesh = im
	icing.position = CAKE + Vector3(0, 0.12, 0)
	icing.material_override = _mat(Color(0.90, 0.80, 0.68))
	add_child(icing)

	# eleven candles: he is eleven
	for i in range(11):
		var a := TAU * float(i) / 11.0
		var r := 0.22
		var p := CAKE + Vector3(cos(a) * r, 0.20, sin(a) * r)
		var candle := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.012
		cm.bottom_radius = 0.014
		cm.height = 0.16
		cm.radial_segments = 4
		candle.mesh = cm
		candle.position = p + Vector3(0, 0.08, 0)
		candle.material_override = _mat(Color(0.90, 0.82, 0.62))
		add_child(candle)
		var flame := MeshInstance3D.new()
		var fq := QuadMesh.new()
		fq.size = Vector2(0.035, 0.07)
		flame.mesh = fq
		flame.position = p + Vector3(0, 0.20, 0)
		var flame_mat := _mat(Color(1.0, 0.78, 0.30), true)
		flame_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		flame.material_override = flame_mat
		add_child(flame)

	_candle_light = OmniLight3D.new()
	_candle_light.light_color = Color(1.0, 0.72, 0.38)
	_candle_light.light_energy = 0.6
	_candle_light.omni_range = 3.2
	_candle_light.shadow_enabled = false
	_candle_light.position = CAKE + Vector3(0, 0.35, 0)
	add_child(_candle_light)


func _banner() -> void:
	# bunting: eight triangles of mis-matched colour, strung across the ceiling
	var cols: Array[Color] = [
		Color(0.78, 0.24, 0.26), Color(0.85, 0.66, 0.22), Color(0.28, 0.52, 0.70),
		Color(0.32, 0.62, 0.40), Color(0.72, 0.36, 0.62), Color(0.85, 0.66, 0.22),
		Color(0.28, 0.52, 0.70), Color(0.78, 0.24, 0.26),
	]
	for i in range(8):
		var x := -3.2 + i * 0.9
		var tri := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.42, 0.5, 0.02)
		tri.mesh = pm
		tri.position = Vector3(x, 2.55, -3.3)
		tri.rotation_degrees = Vector3(180, 0, 0)
		tri.material_override = _mat(cols[i], true)
		add_child(tri)
	# string
	_box(Vector3(0, 2.82, -3.3), Vector3(7.2, 0.015, 0.015), Color(0.60, 0.56, 0.48), false, true)

	var sign3d := Label3D.new()
	sign3d.text = "HAPPY BIRTHDAY"
	sign3d.font_size = 48
	sign3d.pixel_size = 0.0045
	sign3d.modulate = Color(0.94, 0.80, 0.52)
	sign3d.position = Vector3(-1.6, 2.08, -4.2)
	sign3d.no_depth_test = false
	add_child(sign3d)


func _balloons() -> void:
	var cols: Array[Color] = [Color(0.70, 0.22, 0.24), Color(0.28, 0.42, 0.68)]
	for i in range(2):
		var balloon := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.22
		sm.height = 0.48
		sm.radial_segments = 10
		sm.rings = 6
		balloon.mesh = sm
		balloon.position = Vector3(3.3 - i * 0.5, 1.95 + i * 0.15, -4.0)
		balloon.material_override = _mat(cols[i])
		add_child(balloon)
		_box(Vector3(3.3 - i * 0.5, 1.2, -4.0), Vector3(0.012, 1.2, 0.012),
			Color(0.70, 0.68, 0.62), false)


func _lights() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.13, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.47, 0.38)
	env.ambient_light_energy = 0.48
	env.fog_enabled = false
	we.environment = env
	add_child(we)

	# dusk through the window, no shadows
	var dusk := DirectionalLight3D.new()
	dusk.light_color = Color(0.86, 0.52, 0.48)
	dusk.light_energy = 0.25
	dusk.shadow_enabled = false
	dusk.rotation_degrees = Vector3(-18, 70, 0)
	add_child(dusk)

	# one warm bulb over the table
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.84, 0.60)
	lamp.light_energy = 1.05
	lamp.omni_range = 6.5
	lamp.shadow_enabled = false
	lamp.position = Vector3(0, 2.4, -0.7)
	add_child(lamp)
	# the fixture
	var shade := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 0.30
	cm.height = 0.22
	cm.radial_segments = 10
	shade.mesh = cm
	shade.position = Vector3(0, 2.62, -0.7)
	shade.material_override = _mat(Color(0.62, 0.52, 0.38))
	add_child(shade)
	_box(Vector3(0, 2.85, -0.7), Vector3(0.02, 0.35, 0.02), Color(0.20, 0.18, 0.16), false)


# ---------------------------------------------------------------- mum

func _build_mum() -> void:
	mum = Node3D.new()
	mum.position = MUM_POS
	add_child(mum)
	_collider(MUM_POS + Vector3(0, 0.9, 0), Vector3(0.55, 1.8, 0.40))

	var trousers := Color(0.24, 0.26, 0.30)
	var sweater := Color(0.58, 0.44, 0.34)
	var apron := Color(0.78, 0.70, 0.58)
	var skin := Color(0.82, 0.68, 0.56)
	var hair := Color(0.28, 0.20, 0.16)

	for x in [-0.12, 0.12]:
		_part(mum, Vector3(x, 0.35, 0), Vector3(0.14, 0.7, 0.16), trousers)
		_part(mum, Vector3(x, 0.03, 0.02), Vector3(0.16, 0.06, 0.24), Color(0.16, 0.14, 0.13))
	_part(mum, Vector3(0, 0.74, 0), Vector3(0.56, 0.55, 0.36), Color(0.30, 0.34, 0.38))
	_part(mum, Vector3(0, 1.15, 0), Vector3(0.48, 0.52, 0.30), sweater)
	_part(mum, Vector3(0, 1.0, 0.16), Vector3(0.36, 0.62, 0.02), apron)
	_part(mum, Vector3(0, 0.76, 0.17), Vector3(0.40, 0.06, 0.02), apron)
	for x in [-0.30, 0.30]:
		_part(mum, Vector3(x, 1.12, 0), Vector3(0.11, 0.55, 0.12), sweater)
		_part(mum, Vector3(x, 0.85, 0.01), Vector3(0.10, 0.12, 0.11), skin)
	_part(mum, Vector3(0, 1.46, 0), Vector3(0.14, 0.12, 0.14), skin)
	_mum_head = _part(mum, Vector3(0, 1.62, 0), Vector3(0.28, 0.32, 0.27), skin)
	_part(mum, Vector3(0, 1.76, -0.01), Vector3(0.31, 0.12, 0.30), hair)
	_part(mum, Vector3(0, 1.70, -0.17), Vector3(0.16, 0.16, 0.12), hair)
	# eyes. Kind, tired. Not a monster.
	for x in [-0.06, 0.06]:
		_part(mum, Vector3(x, 1.64, 0.14), Vector3(0.03, 0.03, 0.012), Color(0.16, 0.12, 0.10))
	_part(mum, Vector3(0, 1.52, 0.14), Vector3(0.07, 0.012, 0.012), Color(0.46, 0.24, 0.22))
