extends CaveBase
class_name BloodCave
## World 3 -- the red cave. Narrower, hotter, worse. The walls are stained,
## the pools are still, and the lost ones are hungry for a day they never got.
##
## Deliberately NOT gore: no bodies, no dismemberment, nothing to clean up.
## docs/art-direction.md §8 bans body horror, and the fear here is that the
## cave is a place where birthdays went to stop existing.

var spawn := Vector3(0, 0.1, 2)
var exit_pos := Vector3(0, 0, -46)
var exit_radius := 2.0
var hide_radius := 1.8
var hide_spots: Array[Vector3] = [
	Vector3(5.0, 0, -22.0),
	Vector3(-3.0, 0, -30.0),
	Vector3(0.0, 0, -38.0),
]
var checkpoints: Array[Vector3] = [
	Vector3(2.0, 0.1, -14.0),
	Vector3(-3.0, 0.1, -30.0),
]
var patrols: Array = [
	[Vector3(2, 0, -11), Vector3(-2, 0, -16), Vector3(5, 0, -17), Vector3(1, 0, -13)],
	[Vector3(-3, 0, -27), Vector3(3, 0, -33), Vector3(-1, 0, -34), Vector3(2, 0, -29)],
	[Vector3(0, 0, -39), Vector3(-4, 0, -43), Vector3(3, 0, -43), Vector3(1, 0, -40)],
]
var objective := "keep moving  ·  the red pools are not water"
var intro := "WREN: Don't look at the walls. They look back."
var next_scene := "res://scenes/world4_street.tscn"
var is_final := false
var exit_requires_interact := false
var music_pitch := 0.55
var caught_line := "...warm. Red behind your eyes. Wren: \"Breathe. It didn't keep you.\""

var beats: Array = [
	{"pos": Vector3(0, 0, 0), "r": 5.0, "lines": [
		"WREN: It's warm in here. Like a mouth.",
		"You: What is this place?",
		"WREN: Where the days go when nobody counts them."]},
	{"pos": Vector3(-4, 0, -6), "r": 3.5, "lines": [
		"WREN: Stay out of the red. It remembers you.",
		"WREN: Walk quiet. They're all awake here."]},
	{"pos": Vector3(5, 0, -22), "r": 4.0, "lines": [
		"WREN: In here. Crouch. Don't breathe loud.",
		"WREN: ...I can hear them counting."]},
	{"pos": Vector3(2, 0, -14), "r": 3.5, "lines": [
		"checkpoint. The red pulls at your shoes.",
		"WREN: Three of them now. Please run only if they see you."]},
	{"pos": Vector3(0, 0, -38), "r": 3.5, "lines": [
		"WREN: The last door. It smells like our street.",
		"WREN: I don't want to go back. Not like this."]},
]

const PATH: Array[Vector3] = [
	Vector3(0, 0, 2), Vector3(-4, 0, -6), Vector3(2, 0, -14),
	Vector3(5, 0, -22), Vector3(-3, 0, -30), Vector3(0, 0, -38),
	Vector3(0, 0, -46),
]

const ROCK := Color(0.16, 0.07, 0.08)
const ROCK_DEEP := Color(0.10, 0.04, 0.05)
const BLOOD := Color(0.30, 0.03, 0.04)


func _ready() -> void:
	floor_slab(Vector3(0, 0, -22), Vector2(30, 56), Color(0.13, 0.06, 0.07))
	ceiling_slab(Vector3(0, 0, -22), Vector2(30, 56), Color(0.06, 0.02, 0.03), 6.6)
	corridor(PATH, ROCK, 2.8, 2)
	_back_wall()
	_pools()
	_stalactites()
	_hollows()
	exit_arch(exit_pos, Color(0.95, 0.86, 0.72), 0.75)
	# no directional light at all down here. docs/art-direction.md §7.
	atmosphere(Color(0.22, 0.08, 0.08), 0.38, Color(0.06, 0.01, 0.01), 0.05,
		Color(0, 0, 0), 0.0)
	_drips()


func _back_wall() -> void:
	rock(Vector3(0, 2.2, 4.4), Vector3(12, 5, 1.4), ROCK_DEEP)


func _pools() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3011
	for i in range(22):
		var seg := rng.randi_range(0, PATH.size() - 2)
		var t := rng.randf()
		var p: Vector3 = PATH[seg].lerp(PATH[seg + 1], t)
		var dir: Vector3 = (PATH[seg + 1] - PATH[seg]).normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		p += side * rng.randf_range(1.4, 5.5) * (1.0 if rng.randf() > 0.5 else -1.0)
		var pool := MeshInstance3D.new()
		var q := QuadMesh.new()
		var w := rng.randf_range(1.0, 3.2)
		q.size = Vector2(w, w * rng.randf_range(0.4, 0.9))
		pool.mesh = q
		pool.rotation_degrees = Vector3(-90, 0, rng.randf_range(0, 180))
		pool.position = Vector3(p.x, 0.02, p.z)
		pool.material_override = mat(BLOOD, true)
		add_child(pool)
		# a darker rim so it reads as depth, not paint
		var rim := MeshInstance3D.new()
		var rq := QuadMesh.new()
		rq.size = Vector2(w * 1.15, w * 0.55)
		rim.mesh = rq
		rim.rotation_degrees = Vector3(-90, 0, rng.randf_range(0, 180))
		rim.position = Vector3(p.x, 0.01, p.z)
		rim.material_override = mat(Color(0.07, 0.01, 0.02), true)
		add_child(rim)


func _stalactites() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3030
	for i in range(20):
		var p := Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-45, 2))
		var h := rng.randf_range(0.8, 3.0)
		rock(p + Vector3(0, h * 0.5, 0), Vector3(0.4, h, 0.4), ROCK, false)
		rock(p + Vector3(0.3, 6.4 - h * 0.35, 0), Vector3(0.5, h * 0.7, 0.5), ROCK_DEEP, false)


func _hollows() -> void:
	for h in hide_spots:
		rock(h + Vector3(-1.7, 1.2, 0), Vector3(0.9, 2.5, 3.2), ROCK)
		rock(h + Vector3(1.7, 1.2, 0), Vector3(0.9, 2.5, 3.2), ROCK)
		rock(h + Vector3(0, 1.4, -1.5), Vector3(4.2, 2.8, 0.9), ROCK)
		rock(h + Vector3(0, 2.1, 0.6), Vector3(4.2, 0.7, 1.1), ROCK, false)
		hide_marker(h, Color(0.95, 0.85, 0.72))


func _drips() -> void:
	# A handful of thin, still drips. Unlit, so they read as absence.
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	for i in range(14):
		var p := Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-44, 2))
		var drop := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.02, rng.randf_range(0.3, 1.6), 0.02)
		drop.mesh = bm
		drop.position = p + Vector3(0, 5.2, 0)
		drop.material_override = mat(Color(0.5, 0.1, 0.1), true)
		add_child(drop)
