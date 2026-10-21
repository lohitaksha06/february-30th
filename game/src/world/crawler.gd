extends Ghost
class_name Crawler
## The mushroom cave's weird thing. Same chase code as a ghost, wrong shape:
## low and wide, four long legs, head too big and hung forward, no eyes.
## docs/art-direction.md §4.1b -- same rig, amplitude past charm.
## Costs 12 boxes and zero new systems.

func _ready() -> void:
	# Faster in a straight line, narrow sight. It hunts by sound.
	patrol_speed = 1.5
	chase_speed = 4.0
	search_speed = 2.0
	view_dist = 10.0
	catch_dist = 1.5
	super()


func _build() -> void:
	var shell := _mat(Color(0.20, 0.16, 0.22))
	var pale := _mat(Color(0.88, 0.84, 0.78))
	pale.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Low body, head pushed forward on a wrong neck.
	_body = _box(Vector3(0.9, 0.35, 0.7), Vector3(0, 0.55, 0), shell)
	_head = _box(Vector3(0.42, 0.34, 0.40), Vector3(0, 0.62, 0.55), shell)
	_head.rotation_degrees = Vector3(18, 0, -11)
	var face := _box(Vector3(0.34, 0.22, 0.02), Vector3(0, -0.01, 0.21), pale, _head)
	face.scale = Vector3(1.0, 0.55, 1.0)

	# Four legs, all the wrong length. It scuttles.
	var legs := [
		[Vector3(-0.42, 0.28, 0.25), 0.55],
		[Vector3(0.42, 0.30, 0.20), 0.60],
		[Vector3(-0.38, 0.24, -0.28), 0.48],
		[Vector3(0.44, 0.26, -0.24), 0.64],
	]
	for l in legs:
		var p: Vector3 = l[0]
		var h: float = l[1]
		_box(Vector3(0.07, h, 0.07), Vector3(p.x, h * 0.5, p.z), shell)

	# One arm hanging under the head, much too long.
	_box(Vector3(0.08, 0.9, 0.08), Vector3(0.35, 0.35, 0.55), shell)

	var blob := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.2, 1.2)
	blob.mesh = q
	blob.rotation_degrees = Vector3(-90, 0, 0)
	blob.position = Vector3(0, 0.02, 0)
	blob.material_override = _mat(Color(0, 0, 0, 0.5), true)
	add_child(blob)


func _physics_process(delta: float) -> void:
	super(delta)
	# Twitch the head while hunting. Held frames, not smooth motion.
	if _head != null and is_chasing():
		var tw := 1.0 if sin(_t * 14.0) > 0.2 else 0.0
		_head.rotation.z = deg_to_rad(-11.0 + tw * 6.0)
