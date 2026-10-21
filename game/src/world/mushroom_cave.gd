extends CaveBase
class_name MushroomCave
## World 2 -- the bright cave. Silksong-adjacent: glowing mushroom caps,
## rainbow pebbles marking the true path, and things in the dark that are
## almost children. The pretty one is the one that lies.
##
## Layout data (spawn/exit/hides/beats) is read by journey.gd, so story and
## geometry cannot drift apart.

var spawn := Vector3(0, 0.1, 2)
var exit_pos := Vector3(0, 0, -44)
var exit_radius := 2.0
var hide_radius := 1.9
var hide_spots: Array[Vector3] = [
	Vector3(-5.0, 0, -20.0),
	Vector3(4.0, 0, -24.0),
	Vector3(0.0, 0, -36.0),
]
var checkpoints: Array[Vector3] = [
	Vector3(6.0, 0.1, -12.0),
	Vector3(3.0, 0.1, -28.0),
]
var patrols: Array = [
	[Vector3(6, 0, -9), Vector3(1, 0, -14), Vector3(8, 0, -16), Vector3(4, 0, -11)],
	[Vector3(3, 0, -26), Vector3(-1, 0, -31), Vector3(6, 0, -32), Vector3(2, 0, -28)],
]
var objective := "follow the rainbow pebbles  ·  hide under the big caps"
var intro := "WREN: It's brighter than the last one. That's not always good."
var next_scene := "res://scenes/world3_blood.tscn"
var is_final := false
var exit_requires_interact := false
var music_pitch := 0.85
var caught_line := "...the caps are dimmer. Wren is pulling your sleeve. \"Get up. It didn't keep you.\""

var beats: Array = [
	{"pos": Vector3(0, 0, 0), "r": 5.0, "lines": [
		"WREN: Caps are listening. Don't touch them.",
		"WREN: The pebbles remember the way. Follow the colours."]},
	{"pos": Vector3(0, 0, -8), "r": 3.5, "lines": [
		"WREN: This one grew out of something. I don't know what.",
		"You: It's beautiful.",
		"WREN: That's what it wants."]},
	{"pos": Vector3(-5, 0, -20), "r": 4.0, "lines": [
		"WREN: Under the big cap. Crouch. It doesn't look down."]},
	{"pos": Vector3(6, 0, -12), "r": 3.5, "lines": [
		"checkpoint. The pebbles wait.",
		"WREN: Something skitters here. Faster than the lost ones."]},
	{"pos": Vector3(3, 0, -28), "r": 3.5, "lines": [
		"checkpoint. Almost out of the light.",
		"WREN: The next cave is red. I don't want to go in."]},
	{"pos": Vector3(0, 0, -36), "r": 3.5, "lines": [
		"WREN: The door's warm. Warm means something's on the other side."]},
]

const PATH: Array[Vector3] = [
	Vector3(0, 0, 2), Vector3(0, 0, -6), Vector3(6, 0, -12),
	Vector3(-5, 0, -20), Vector3(3, 0, -28), Vector3(0, 0, -36),
	Vector3(0, 0, -44),
]

const CAP_COLOURS: Array[Color] = [
	Color(0.35, 0.95, 0.85),  # teal
	Color(0.95, 0.45, 0.85),  # pink
	Color(0.55, 0.55, 1.0),   # blue
	Color(0.95, 0.85, 0.35),  # yellow
	Color(0.55, 1.0, 0.55),   # green
]

const PEBBLE_COLOURS: Array[Color] = [
	Color(1.0, 0.35, 0.35), Color(1.0, 0.65, 0.25), Color(1.0, 0.95, 0.35),
	Color(0.4, 1.0, 0.45), Color(0.35, 0.75, 1.0), Color(0.75, 0.45, 1.0),
]


func _ready() -> void:
	floor_slab(Vector3(0, 0, -21), Vector2(36, 54), Color(0.12, 0.16, 0.18))
	ceiling_slab(Vector3(0, 0, -21), Vector2(36, 54), Color(0.05, 0.07, 0.09), 8.0)
	corridor(PATH, Color(0.14, 0.18, 0.22), 3.4, 2)
	_arch_wall()
	_mushrooms()
	_pebbles()
	_hollows()
	exit_arch(exit_pos, Color(0.62, 0.95, 0.78), 0.7)
	atmosphere(Color(0.16, 0.22, 0.28), 0.5, Color(0.03, 0.07, 0.08), 0.035,
		Color(0.6, 0.8, 0.9), 0.12)


func _arch_wall() -> void:
	rock(Vector3(0, 2.2, 4.6), Vector3(14, 5, 1.6), Color(0.14, 0.18, 0.22))


func _mushrooms() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2030
	# 3 real lights only. The rest of the glow is emission, which is free.
	var lit := 0
	for i in range(64):
		# spawn along the path, offset to the sides, never on the walkline
		var seg := rng.randi_range(0, PATH.size() - 2)
		var t := rng.randf()
		var base: Vector3 = PATH[seg].lerp(PATH[seg + 1], t)
		var dir: Vector3 = (PATH[seg + 1] - PATH[seg]).normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var off := rng.randf_range(2.0, 8.5) * (1.0 if rng.randf() > 0.5 else -1.0)
		var p := base + side * off
		p.z += rng.randf_range(-1.5, 1.5)
		var scale := rng.randf_range(0.5, 1.9)
		var col: Color = CAP_COLOURS[rng.randi_range(0, CAP_COLOURS.size() - 1)]
		_mushroom(p, scale, col, rng)
		# two or three clusters get a light. The budget is the budget.
		if lit < 3 and scale > 1.5 and absf(off) < 5.0:
			lit += 1
			var lamp := OmniLight3D.new()
			lamp.light_color = col
			lamp.light_energy = 0.9
			lamp.omni_range = 7.0
			lamp.shadow_enabled = false
			lamp.position = p + Vector3(0, 1.2, 0)
			add_child(lamp)


func _mushroom(p: Vector3, s: float, col: Color, rng: RandomNumberGenerator) -> void:
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.10 * s
	sm.bottom_radius = 0.16 * s
	sm.height = 0.9 * s
	sm.radial_segments = 6
	stem.mesh = sm
	stem.position = p + Vector3(0, 0.45 * s, 0)
	stem.rotation_degrees = Vector3(rng.randf_range(-7, 7), 0, rng.randf_range(-7, 7))
	stem.material_override = mat(Color(0.82, 0.78, 0.68) * (0.5 + s * 0.2))
	add_child(stem)

	var cap := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.55 * s
	cm.height = 0.55 * s
	cm.radial_segments = 8
	cm.rings = 4
	cap.mesh = cm
	cap.position = p + Vector3(0, 0.95 * s, 0)
	cap.scale = Vector3(1.0, 0.55, 1.0)
	cap.material_override = mat(col, false, 1.7)
	add_child(cap)

	# gills: a dark disc under the cap. Cheapest depth cue there is.
	var gills := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 0.52 * s
	gm.bottom_radius = 0.52 * s
	gm.height = 0.02
	gm.radial_segments = 8
	gills.mesh = gm
	gills.position = p + Vector3(0, 0.93 * s, 0)
	gills.material_override = mat(col * 0.25)
	add_child(gills)


func _pebbles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3029
	for i in range(PATH.size() - 1):
		var a: Vector3 = PATH[i]
		var b: Vector3 = PATH[i + 1]
		var steps := int(a.distance_to(b) / 0.9)
		for k in range(steps):
			var t := float(k) / maxf(1.0, float(steps))
			var p: Vector3 = a.lerp(b, t)
			# pebbles hug the centre line, slightly offset each step
			p += Vector3(rng.randf_range(-0.45, 0.45), 0.03, rng.randf_range(-0.45, 0.45))
			var peb := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(rng.randf_range(0.10, 0.22), 0.05, rng.randf_range(0.10, 0.22))
			peb.mesh = bm
			peb.position = p
			peb.rotation_degrees = Vector3(0, rng.randf_range(0, 360), 0)
			peb.material_override = mat(PEBBLE_COLOURS[rng.randi_range(0, PEBBLE_COLOURS.size() - 1)], true)
			add_child(peb)


func _hollows() -> void:
	var col := Color(0.20, 0.24, 0.26)
	for h in hide_spots:
		# a ring of fat stems + a low shelf of caps you must duck under
		for s in [-1.9, 1.9]:
			var stem := MeshInstance3D.new()
			var sm := CylinderMesh.new()
			sm.top_radius = 0.42
			sm.bottom_radius = 0.55
			sm.height = 2.6
			sm.radial_segments = 7
			stem.mesh = sm
			stem.position = h + Vector3(s, 1.3, -0.6)
			stem.material_override = mat(col)
			add_child(stem)
		rock(h + Vector3(0, 1.35, -1.5), Vector3(4.2, 2.7, 0.7), col)
		var brow := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(4.2, 0.5, 1.2)
		brow.mesh = bm
		brow.position = h + Vector3(0, 2.2, 0.6)
		brow.material_override = mat(Color(0.24, 0.30, 0.30))
		add_child(brow)
		# glowing rim so the player can find safety in the dark
		var rim := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(4.0, 0.12)
		rim.mesh = q
		rim.position = h + Vector3(0, 2.0, 1.18)
		rim.material_override = mat(Color(0.55, 1.0, 0.85), true, 2.0)
		add_child(rim)
		hide_marker(h, Color(0.65, 1.0, 0.9))
