extends Node3D
class_name CaveBase
## Shared code-built geometry helpers for the two cave worlds. Same rules as
## every other level: boxes, albedo only, no shadow maps, no CSG.
## Subclasses own their layout and story data (spawn / exit / hides / beats).


func mat(c: Color, unshaded := false, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func rock(pos: Vector3, size: Vector3, col: Color, collide := true, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(col)
	mi.position = pos
	mi.rotation.y = rot_y
	add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		body.position = pos
		body.rotation.y = rot_y
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		add_child(body)
	return mi


func floor_slab(center: Vector3, size: Vector2, col: Color, collide := true) -> void:
	var f := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	f.mesh = pm
	f.position = Vector3(center.x, 0.0, center.z)
	f.material_override = mat(col)
	add_child(f)
	if collide:
		var body := StaticBody3D.new()
		body.position = Vector3(center.x, -0.25, center.z)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(size.x, 0.5, size.y)
		cs.shape = sh
		body.add_child(cs)
		add_child(body)


func ceiling_slab(center: Vector3, size: Vector2, col: Color, h := 7.0) -> void:
	var c := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, 0.6, size.y)
	c.mesh = bm
	c.position = Vector3(center.x, h, center.z)
	c.material_override = mat(col)
	add_child(c)


## Rock walls flanking a polyline. Same approach as the cavern: a few offset
## chunks per side so it reads as grown, and the corridor stays readable.
func corridor(points: Array, col: Color, half_width := 3.2, density := 2) -> void:
	for i in range(points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var mid := (a + b) * 0.5
		var dir: Vector3 = (b - a).normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var length: float = a.distance_to(b) + 3.0
		for s in [-1.0, 1.0]:
			for k in range(density):
				var off := half_width + k * 1.1
				var h := randf_range(3.2, 5.4) - k * 0.6
				rock(mid + side * s * off + dir * (k * 1.1 - 0.5),
					Vector3(1.6, h, length / density * 1.05), col,
					true, randf_range(-0.1, 0.1))


## A framed doorway. Solid posts, a lintel, and a cloth-like veil. This is
## how every world says "the next one is this way".
func exit_arch(pos: Vector3, glow: Color, veil_alpha := 0.8) -> void:
	for x in [-0.85, 0.85]:
		var post := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.24, 2.6, 0.24)
		post.mesh = bm
		post.material_override = mat(glow, true)
		post.position = pos + Vector3(x, 1.3, 0)
		add_child(post)
	var lintel := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(1.95, 0.24, 0.24)
	lintel.mesh = lm
	lintel.material_override = mat(glow, true)
	lintel.position = pos + Vector3(0, 2.7, 0)
	add_child(lintel)
	var veil := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.5, 2.4)
	veil.mesh = q
	veil.position = pos + Vector3(0, 1.3, 0)
	veil.material_override = mat(Color(glow.r, glow.g, glow.b, veil_alpha), true)
	add_child(veil)
	var lamp := OmniLight3D.new()
	lamp.light_color = glow
	lamp.light_energy = 1.5
	lamp.omni_range = 8.0
	lamp.shadow_enabled = false
	lamp.position = pos + Vector3(0, 1.9, 1.0)
	add_child(lamp)


## One hemisphere-ish ambient + fog + a single directional. Indoors, no
## directional at all in the bloody cave. docs/art-direction.md §7.
func atmosphere(amb_col: Color, amb_energy: float, fog_col: Color, fog_density: float,
		moon_col: Color = Color(0, 0, 0), moon_energy := 0.0) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = fog_col * 0.4
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = amb_col
	env.ambient_light_energy = amb_energy
	env.fog_enabled = true
	env.fog_light_color = fog_col
	env.fog_density = fog_density
	we.environment = env
	add_child(we)
	if moon_energy > 0.0:
		var sun := DirectionalLight3D.new()
		sun.light_color = moon_col
		sun.light_energy = moon_energy
		sun.shadow_enabled = false
		sun.rotation_degrees = Vector3(-52, 25, 0)
		add_child(sun)


func hide_marker(h: Vector3, colour: Color) -> void:
	var mark := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 0.3)
	mark.mesh = q
	mark.rotation_degrees = Vector3(-90, 0, 0)
	mark.position = h + Vector3(0, 0.03, 1.3)
	mark.material_override = mat(colour, true)
	add_child(mark)
