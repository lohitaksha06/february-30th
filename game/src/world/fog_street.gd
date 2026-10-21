extends CaveBase
class_name FogStreet
## World 4 -- the street. Your street, fogged until it forgets itself.
## No cars, no people, one lit window, and your front door at the end.
##
## This is the last world. There is no exit arch: the exit is the door of
## your own house, and journey.gd turns that into the goodbye.
##
## Same budget as the caves: boxes, albedo only, no shadow maps, fog does
## the heavy lifting. Three streetlights, no more.

var spawn := Vector3(0, 0.1, 8)
var exit_pos := Vector3(0, 0, -39.5)
var exit_radius := 2.2
var exit_requires_interact := true
var hide_radius := 1.9
var hide_spots: Array[Vector3] = [
	Vector3(-6.2, 0, -7.0),
	Vector3(6.5, 0, -19.0),
	Vector3(-6.3, 0, -31.0),
]
var checkpoints: Array[Vector3] = [
	Vector3(0, 0.1, -16.0),
	Vector3(0, 0.1, -30.0),
]
var patrols: Array = [
	[Vector3(0, 0, -12), Vector3(4, 0, -20), Vector3(-3, 0, -26), Vector3(2, 0, -17)],
	[Vector3(-2, 0, -34), Vector3(3, 0, -35), Vector3(0, 0, -30), Vector3(-4, 0, -31)],
]
var objective := "walk home  ·  the fog is not weather"
var intro := "WREN: I know this street. I used to live on it."
var next_scene := "res://scenes/ending.tscn"
var is_final := true
var music_pitch := 0.95

var beats: Array = [
	{"pos": Vector3(0, 0, 6), "r": 5.0, "lines": [
		"The street. Your street.",
		"No cars. No one at the windows.",
		"WREN: It's foggy the way dreams are foggy."]},
	{"pos": Vector3(0, 0, -6), "r": 4.5, "lines": [
		"WREN: That one's mine. The blue door.",
		"You: There's no blue door there.",
		"WREN: ...There used to be."]},
	{"pos": Vector3(-6.2, 0, -7), "r": 4.0, "lines": [
		"WREN: Behind the hedge. Crouch. It walks the middle of the road."]},
	{"pos": Vector3(0, 0, -16), "r": 4.0, "lines": [
		"checkpoint. A streetlight buzzes above you.",
		"Your house is at the end. The porch light is on."]},
	{"pos": Vector3(6.5, 0, -19), "r": 4.0, "lines": [
		"WREN: Under the bins. Don't breathe loud."]},
	{"pos": Vector3(-6.3, 0, -31), "r": 4.0, "lines": [
		"WREN: We're close. I can hear her radio."]},
	{"pos": Vector3(0, 0, -34), "r": 4.5, "lines": [
		"WREN: I don't think I can go in.",
		"WREN: The door only knows one of us."]},
]

const ROAD_COL := Color(0.10, 0.11, 0.13)
const WALK_COL := Color(0.17, 0.18, 0.20)
const HOUSE_COLS: Array[Color] = [
	Color(0.20, 0.19, 0.22),
	Color(0.23, 0.20, 0.19),
	Color(0.18, 0.20, 0.21),
	Color(0.22, 0.22, 0.24),
]
const WINDOW_WARM := Color(1.0, 0.82, 0.48)
const FOG := Color(0.30, 0.33, 0.38)


func _ready() -> void:
	_ground()
	_houses()
	_streetlights()
	_hides()
	_your_house()
	_props()
	atmosphere(Color(0.34, 0.36, 0.42), 0.40, FOG, 0.075,
		Color(0.55, 0.62, 0.75), 0.10)


func mat(c: Color, unshaded := false, _emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func box(pos: Vector3, size: Vector3, col: Color, collide := true, unshaded := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(col, unshaded)
	mi.position = pos
	add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		body.position = pos
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		add_child(body)
	return mi


func _ground() -> void:
	# road
	var road := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 56)
	road.mesh = pm
	road.position = Vector3(0, 0, -18)
	road.material_override = mat(ROAD_COL)
	add_child(road)
	# the road is walkable without collision tricks: one big slab below
	box(Vector3(0, -0.25, -18), Vector3(9.0, 0.5, 56), ROAD_COL)
	# sidewalks + curbs
	for s in [-1.0, 1.0]:
		box(Vector3(6.0 * s, 0.06, -18), Vector3(4.0, 0.12, 56), WALK_COL)
		box(Vector3(4.0 * s, 0.10, -18), Vector3(0.24, 0.22, 56), Color(0.24, 0.25, 0.27))
	# centre line, dashed
	for i in range(14):
		box(Vector3(0, 0.012, 4.0 - i * 3.6), Vector3(0.12, 0.02, 1.4),
			Color(0.55, 0.55, 0.50), false, true)
	# pavement at the end so the house has something to stand on
	box(Vector3(0, 0.05, -40), Vector3(12, 0.1, 6), Color(0.20, 0.20, 0.22))


func _houses() -> void:
	# x = -1 left, +1 right. Four per side, all facing the road.
	for i in range(4):
		var z := -2.0 - i * 9.5
		_house(-1.0, z, -1.0, HOUSE_COLS[i % HOUSE_COLS.size()], false)
		_house(1.0, z + 4.2, 1.0, HOUSE_COLS[(i + 2) % HOUSE_COLS.size()], i == 1)


func _house(side: float, z: float, facing: float, col: Color, lit: bool) -> void:
	var x := side * 8.6
	# body + roof
	box(Vector3(x, 2.2, z), Vector3(5.0, 4.4, 6.4), col)
	box(Vector3(x, 4.55, z), Vector3(5.4, 0.5, 6.8), col * 0.8)
	box(Vector3(x, 5.0, z), Vector3(3.6, 0.5, 5.0), col * 0.7)
	# door
	box(Vector3(x - facing * 2.52, 1.15, z + 1.6), Vector3(0.08, 2.3, 0.95),
		Color(0.16, 0.10, 0.09))
	# two windows, front face. One warm if lit, the rest dark.
	for k in range(2):
		var wz: float = z - 1.2 + k * 2.4
		var wcol := WINDOW_WARM if (lit and k == 0) else Color(0.06, 0.08, 0.10)
		var w := box(Vector3(x - facing * 2.52, 2.6, wz), Vector3(0.06, 1.0, 1.2),
			wcol, false, true)
		w.name = "Window"
		# frame cross, so the window reads even at 320x180
		box(Vector3(x - facing * 2.56, 2.6, wz), Vector3(0.03, 1.1, 0.06),
			Color(0.10, 0.10, 0.11), false, true)
		box(Vector3(x - facing * 2.56, 2.6, wz), Vector3(0.03, 0.06, 1.3),
			Color(0.10, 0.10, 0.11), false, true)
	# a low garden wall, because every street has one
	box(Vector3(x - facing * 3.6, 0.45, z), Vector3(0.25, 0.9, 5.6),
		Color(0.23, 0.23, 0.24))
	if lit:
		var lamp := OmniLight3D.new()
		lamp.light_color = WINDOW_WARM
		lamp.light_energy = 0.7
		lamp.omni_range = 6.0
		lamp.shadow_enabled = false
		lamp.position = Vector3(x - facing * 2.8, 2.6, z - 1.2)
		add_child(lamp)


func _streetlights() -> void:
	for i in range(3):
		var z := -4.0 - i * 13.0
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * 5.2
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06
		cm.bottom_radius = 0.09
		cm.height = 4.6
		cm.radial_segments = 6
		post.mesh = cm
		post.position = Vector3(x, 2.3, z)
		post.material_override = mat(Color(0.13, 0.13, 0.15))
		add_child(post)
		box(Vector3(x, 4.62, z), Vector3(0.9, 0.08, 0.12), Color(0.13, 0.13, 0.15), false)
		var head := box(Vector3(x - side * 0.45, 4.52, z), Vector3(0.38, 0.16, 0.24),
			Color(1.0, 0.90, 0.66), false, true)
		head.name = "LampHead"
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.88, 0.60)
		lamp.light_energy = 1.15
		lamp.omni_range = 11.0
		lamp.shadow_enabled = false
		lamp.position = Vector3(x - side * 0.45, 4.2, z)
		add_child(lamp)


func _hides() -> void:
	for h in hide_spots:
		# hedge (left) / bins (right) / bus shelter (left)
		if h.x < 0.0 and h.z > -10.0:
			_hedge(h)
		elif h.x > 0.0:
			_bins(h)
		else:
			_shelter(h)


func _hedge(h: Vector3) -> void:
	box(h + Vector3(0.4, 0.9, -1.1), Vector3(3.6, 1.8, 0.8), Color(0.12, 0.18, 0.13))
	box(h + Vector3(0.4, 0.9, 1.1), Vector3(3.6, 1.8, 0.8), Color(0.12, 0.18, 0.13))
	box(h + Vector3(-1.5, 0.9, 0), Vector3(0.8, 1.8, 3.0), Color(0.12, 0.18, 0.13))
	hide_marker(h, Color(0.62, 0.92, 0.70))


func _bins(h: Vector3) -> void:
	for k in range(2):
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.62, 1.05, 0.62)
		b.mesh = bm
		b.position = h + Vector3(-0.9 + k * 0.75, 0.53, -0.9)
		b.material_override = mat(Color(0.14, 0.18, 0.16))
		add_child(b)
	box(h + Vector3(0, 1.1, -1.5), Vector3(2.4, 0.4, 1.2), Color(0.15, 0.17, 0.16))
	hide_marker(h, Color(0.62, 0.92, 0.70))


func _shelter(h: Vector3) -> void:
	box(h + Vector3(0, 0.9, -1.2), Vector3(2.6, 1.8, 0.15), Color(0.16, 0.20, 0.22))
	box(h + Vector3(-1.2, 0.9, 0), Vector3(0.16, 1.8, 2.4), Color(0.16, 0.20, 0.22))
	box(h + Vector3(0, 1.9, 0), Vector3(2.8, 0.16, 2.6), Color(0.13, 0.16, 0.18), false)
	hide_marker(h, Color(0.62, 0.92, 0.70))


func _your_house() -> void:
	# Wider, closer to the road, porch light on.
	var z := -43.0
	box(Vector3(0, 2.6, z), Vector3(9.0, 5.2, 7.0), Color(0.21, 0.19, 0.20))
	box(Vector3(0, 5.35, z), Vector3(9.6, 0.6, 7.6), Color(0.16, 0.14, 0.15))
	box(Vector3(0, 5.9, z), Vector3(6.4, 0.7, 5.2), Color(0.14, 0.12, 0.13))
	# porch
	box(Vector3(0, 0.18, -39.0), Vector3(4.2, 0.36, 2.2), Color(0.18, 0.17, 0.18))
	box(Vector3(0, 2.7, -38.4), Vector3(4.6, 0.18, 2.6), Color(0.13, 0.12, 0.13), false)
	for s in [-1.0, 1.0]:
		box(Vector3(2.0 * s, 1.4, -38.3), Vector3(0.16, 2.7, 0.16), Color(0.16, 0.14, 0.15))
	# front door: dark red, slightly ajar. This is the exit.
	box(Vector3(-0.35, 1.25, -39.55), Vector3(0.10, 2.5, 1.15), Color(0.28, 0.08, 0.08))
	box(Vector3(-0.42, 1.25, -39.55), Vector3(0.04, 2.3, 0.95), Color(0.04, 0.02, 0.02), false, true)
	# porch light
	box(Vector3(0, 2.95, -39.1), Vector3(0.26, 0.34, 0.20), Color(1.0, 0.86, 0.60), false, true)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.84, 0.56)
	lamp.light_energy = 1.5
	lamp.omni_range = 9.0
	lamp.shadow_enabled = false
	lamp.position = Vector3(0, 3.0, -38.6)
	add_child(lamp)
	# number plate, no number
	box(Vector3(0.95, 1.95, -39.5), Vector3(0.3, 0.22, 0.05), Color(0.55, 0.52, 0.45), false)
	# hedge along the front
	for s in [-1.0, 1.0]:
		box(Vector3(3.6 * s, 0.5, -38.0), Vector3(3.4, 1.0, 1.0), Color(0.11, 0.15, 0.12))
	# warm window upstairs, where you sleep
	box(Vector3(-2.4, 3.9, -39.48), Vector3(1.2, 1.0, 0.06), WINDOW_WARM, false, true)
	box(Vector3(-2.4, 3.9, -39.52), Vector3(0.06, 1.1, 0.04), Color(0.12, 0.10, 0.10), false, true)
	box(Vector3(-2.4, 3.9, -39.52), Vector3(1.3, 0.06, 0.04), Color(0.12, 0.10, 0.10), false, true)


func _props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3131
	# wheelie bins, a bike, a sign. Set dressing only; no collisions where
	# the player can get snagged.
	for i in range(6):
		var p := Vector3(rng.randf_range(-6.8, 6.8), 0.45, rng.randf_range(-36, 0))
		if absf(p.x) < 4.3:
			p.x = signf(p.x + 0.01) * 5.0
		box(p, Vector3(0.55, 0.9, 0.5), Color(0.15, 0.17, 0.16), false)
	# a bicycle lying in the road, because someone left in a hurry
	box(Vector3(2.4, 0.35, -24), Vector3(1.5, 0.08, 0.5), Color(0.12, 0.12, 0.13), false)
	box(Vector3(2.4, 0.62, -24), Vector3(0.08, 0.55, 0.08), Color(0.12, 0.12, 0.13), false)
	# hanging sign that has forgotten its words
	box(Vector3(-5.4, 2.4, -14), Vector3(0.9, 0.55, 0.05), Color(0.18, 0.16, 0.14), false)
	box(Vector3(-5.4, 3.0, -14), Vector3(0.05, 1.0, 0.05), Color(0.12, 0.12, 0.13), false)
