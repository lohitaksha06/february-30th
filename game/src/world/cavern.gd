extends Node3D
## The cavern. The other world, first ground: a gloomy winding hollow.
##
## Same rules as the house: everything from code, albedo only, no shadow
## maps. One directional (moon through the cracks) + exit glow + one red
## ember. Fog does the rest. ~80 boxes, still nothing for a 2017 iGPU.

const PATH: Array[Vector3] = [
	Vector3(0, 0, 2),     # entry: where you land
	Vector3(0, 0, -8),
	Vector3(5, 0, -14),   # Ghost A ground + checkpoint 1
	Vector3(-4, 0, -22),  # hollow rocks (hide)
	Vector3(2, 0, -30),   # Ghost B ground + checkpoint 2
	Vector3(0, 0, -38),   # the white door
]

const HIDE_SPOTS: Array[Vector3] = [
	Vector3(3.4, 0, -10.5),
	Vector3(-6.2, 0, -20.5),
	Vector3(5.2, 0, -28.0),
]
const HIDE_RADIUS := 1.7

var _flies: Array[Node3D] = []
var _wing_l: Array[MeshInstance3D] = []
var _wing_r: Array[MeshInstance3D] = []
var _t := 0.0


func _ready() -> void:
	_floor_ceiling()
	_walls()
	_stalagmites()
	_hide_hollows()
	_exit_door()
	_butterflies()
	_lights()


func path_point(i: int) -> Vector3:
	return PATH[clampi(i, 0, PATH.size() - 1)]


func _mat(c: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _rock(pos: Vector3, size: Vector3, col: Color, collide := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col)
	mi.position = pos
	mi.rotation.y = randf() * 0.15
	add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		body.position = pos
		body.rotation.y = mi.rotation.y
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		add_child(body)
	return mi


func _floor_ceiling() -> void:
	var rock_col := Color(0.10, 0.11, 0.15)
	var f := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(34, 52)
	f.mesh = pm
	f.position = Vector3(0, 0, -18)
	f.material_override = _mat(Color(0.13, 0.13, 0.17))
	add_child(f)
	var fbody := StaticBody3D.new()
	fbody.position = Vector3(0, -0.25, -18)
	var fc := CollisionShape3D.new()
	var fs := BoxShape3D.new()
	fs.size = Vector3(34, 0.5, 52)
	fc.shape = fs
	fbody.add_child(fc)
	add_child(fbody)

	var c := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(34, 0.5, 52)
	c.mesh = cm
	c.position = Vector3(0, 7.5, -18)
	c.material_override = _mat(Color(0.05, 0.05, 0.08))
	add_child(c)
	# scattered pale cracks in the ceiling: the only "stars" down here
	for i in range(12):
		var crack := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(randf_range(0.4, 1.4), randf_range(0.06, 0.14))
		crack.mesh = q
		crack.rotation_degrees = Vector3(90, 0, randf_range(0, 180))
		crack.position = Vector3(randf_range(-12, 12), 7.2, randf_range(-40, 2))
		crack.material_override = _mat(Color(0.55, 0.65, 0.85), true)
		add_child(crack)


func _walls() -> void:
	# Flank every path segment with rock so the route reads without a map.
	var col := Color(0.11, 0.12, 0.16)
	for i in range(PATH.size() - 1):
		var a: Vector3 = PATH[i]
		var b: Vector3 = PATH[i + 1]
		var mid := (a + b) * 0.5
		var dir: Vector3 = (b - a).normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var length: float = a.distance_to(b) + 3.0
		for s in [-1.0, 1.0]:
			# two offset chunks per side so the wall feels grown, not built
			_rock(mid + side * s * 3.4, Vector3(1.6, randf_range(3.2, 5.2), length * 0.62), col)
			_rock(mid + side * s * 4.6 + dir * 1.2, Vector3(1.8, randf_range(2.6, 4.4), length * 0.45), col)
	# back wall behind entry so you can't walk off the world
	_rock(Vector3(0, 2.2, 4.5), Vector3(14, 5, 1.6), col)


func _stalagmites() -> void:
	var col := Color(0.14, 0.14, 0.19)
	var rng := RandomNumberGenerator.new()
	rng.seed = 30  # the 30th seeds its own cavern
	for i in range(26):
		var x := rng.randf_range(-11.0, 11.0)
		var z := rng.randf_range(-40.0, 2.0)
		# keep the path itself walkable: skip anything near it
		var near := false
		for p in PATH:
			if Vector2(x, z).distance_to(Vector2(p.x, p.z)) < 2.6:
				near = true
				break
		if near:
			continue
		var h := rng.randf_range(0.8, 3.4)
		_rock(Vector3(x, h * 0.5, z), Vector3(rng.randf_range(0.5, 1.1), h, rng.randf_range(0.5, 1.1)), col)
		# stalactite above, hanging
		_rock(Vector3(x + 0.4, 7.5 - h * 0.3, z), Vector3(0.5, h * 0.6, 0.5), col, false)


func _hide_hollows() -> void:
	# Alcoves of rock with a dark mouth. Crouch inside: ghosts can't see you.
	var col := Color(0.16, 0.15, 0.19)
	for h in HIDE_SPOTS:
		_rock(h + Vector3(-1.6, 1.1, 0), Vector3(0.9, 2.4, 3.4), col)
		_rock(h + Vector3(1.6, 1.1, 0), Vector3(0.9, 2.4, 3.4), col)
		_rock(h + Vector3(0, 1.3, -1.6), Vector3(4.0, 2.8, 0.9), col)
		# low brow: you must crouch to be fully inside
		_rock(h + Vector3(0, 2.0, 0.6), Vector3(4.0, 0.7, 1.0), col, false)
		# marker bones? No. A white pebble line marks safety, butterfly-white.
		var mark := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.6, 0.3)
		mark.mesh = q
		mark.rotation_degrees = Vector3(-90, 0, 0)
		mark.position = h + Vector3(0, 0.03, 1.4)
		mark.material_override = _mat(Color(0.8, 0.82, 0.85), true)
		add_child(mark)


func _exit_door() -> void:
	# The white door: a glowing frame at the end of the path. Walk in to end.
	var glow := _mat(Color(0.92, 0.94, 0.96), true)
	for x in [-0.8, 0.8]:
		var post := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.25, 2.6, 0.25)
		post.mesh = bm
		post.material_override = glow
		post.position = Vector3(x, 1.3, -38)
		add_child(post)
	var lintel := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(1.85, 0.25, 0.25)
	lintel.mesh = lm
	lintel.material_override = glow
	lintel.position = Vector3(0, 2.7, -38)
	add_child(lintel)
	var veil := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.4, 2.4)
	veil.mesh = q
	veil.position = Vector3(0, 1.3, -38)
	veil.material_override = _mat(Color(0.9, 0.92, 0.95, 0.75), true)
	add_child(veil)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(0.85, 0.9, 1.0)
	lamp.light_energy = 1.6
	lamp.omni_range = 9.0
	lamp.shadow_enabled = false
	lamp.position = Vector3(0, 1.8, -37)
	add_child(lamp)


func _butterflies() -> void:
	# White butterflies fly the true path on a loop. Follow them, not Wren.
	var wing_mat := _mat(Color(0.95, 0.95, 0.97), true)
	var loop: Array[Vector3] = []
	loop.append_array(PATH)
	for i in range(8):
		var fly := Node3D.new()
		fly.name = "Butterfly%d" % i
		var body := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.03, 0.03, 0.09)
		body.mesh = bb
		body.material_override = _mat(Color(0.9, 0.9, 0.92), true)
		fly.add_child(body)
		for side in [-1.0, 1.0]:
			var wing := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.11, 0.14)
			wing.mesh = q
			wing.material_override = wing_mat
			wing.position = Vector3(side * 0.06, 0.02, 0)
			fly.add_child(wing)
			if side < 0.0:
				_wing_l.append(wing)
			else:
				_wing_r.append(wing)
		fly.set_meta("phase", float(i) / 8.0)
		fly.position = PATH[0] + Vector3(0, 1.2, 0)
		add_child(fly)
		_flies.append(fly)


func _butterfly_path_pos(t: float) -> Vector3:
	# t in 0..1 along the whole PATH, looped
	var total := 0.0
	var segs: Array[float] = []
	for i in range(PATH.size() - 1):
		var l: float = PATH[i].distance_to(PATH[i + 1])
		segs.append(l)
		total += l
	var d := fmod(t, 1.0) * total
	for i in range(segs.size()):
		if d <= segs[i]:
			var f: float = d / segs[i] if segs[i] > 0.0 else 0.0
			return PATH[i].lerp(PATH[i + 1], f) + Vector3(0, 1.2, 0)
		d -= segs[i]
	return PATH[PATH.size() - 1] + Vector3(0, 1.2, 0)


func _process(delta: float) -> void:
	_t += delta
	for i in range(_flies.size()):
		var fly: Node3D = _flies[i]
		var phase: float = float(fly.get_meta("phase"))
		# slow circuit of the true path + personal wobble so it feels alive
		var p := _butterfly_path_pos(phase + _t * 0.008)
		p += Vector3(sin(_t * 2.1 + float(i) * 1.7) * 0.5, sin(_t * 3.3 + float(i)) * 0.25, cos(_t * 1.7 + float(i) * 2.3) * 0.5)
		var prev: Vector3 = fly.position
		fly.position = p
		var mv: Vector3 = p - prev
		if mv.length() > 0.0001:
			fly.rotation.y = lerp_angle(fly.rotation.y, atan2(-mv.x, -mv.z), minf(1.0, delta * 5.0))
	# wings: two quads beating. 16 nodes, one sin each. Nothing.
	var flap := sin(_t * 22.0) * 0.65
	for w in _wing_l:
		w.rotation.y = flap
	for w in _wing_r:
		w.rotation.y = -flap


func _lights() -> void:
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.01, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.14, 0.16, 0.24)
	env.ambient_light_energy = 0.45
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.03, 0.06)
	env.fog_density = 0.06
	amb.environment = env
	add_child(amb)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.3
	moon.shadow_enabled = false
	moon.rotation_degrees = Vector3(-55, 30, 0)
	add_child(moon)

	# one ember deep in the cavern: something was here. Or is.
	var ember := OmniLight3D.new()
	ember.light_color = Color(0.85, 0.2, 0.12)
	ember.light_energy = 1.0
	ember.omni_range = 10.0
	ember.shadow_enabled = false
	ember.position = Vector3(-4, 1.0, -22)
	add_child(ember)
