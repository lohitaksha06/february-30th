extends Node3D
## Wren — the child in the wardrobe. Part 1 version.
## ~14 boxes, unlit-ish StandardMaterial, deliberately wrong:
## head 4% too big, left arm 6% longer, eyes 2px off. docs/art-direction.md §4.1.
## No rig, no import, no PC load. Breathes via sin().

var _t := 0.0
var breathing := true
var _head: MeshInstance3D
var _body: MeshInstance3D
var _eyes: Array[MeshInstance3D] = []
var _blink_t := 0.0

## Act 1 companion mode: trail the player instead of sitting.
var following := false
var follow_target: Node3D = null
const FOLLOW_DIST := 1.7
const FOLLOW_SPEED := 2.7


func _ready() -> void:
	_build()
	visible = false  # prologue reveals us


func _build() -> void:
	var skin := _mat(Color(0.76, 0.66, 0.56))
	var pj := _mat(Color(0.52, 0.60, 0.76))        # your pyjamas, inside-out = paler
	var pj_dark := _mat(Color(0.42, 0.50, 0.66))
	var dark := _mat(Color(0.03, 0.03, 0.045))     # eyes / mouth: drawn wrong
	var hair := _mat(Color(0.13, 0.10, 0.08))
	var hat := _mat(Color(0.62, 0.14, 0.18))       # party hat, too small
	var jacket := _mat(Color(0.40, 0.33, 0.26))

	# Torso, sitting. A collar and a placket so the pyjama reads as clothing
	# and not as one white slab in the torchlight.
	_body = _box(Vector3(0.36, 0.40, 0.24), Vector3(0, 0.36, 0), pj)
	_box(Vector3(0.20, 0.05, 0.02), Vector3(0, 0.545, 0.125), pj_dark)
	_box(Vector3(0.018, 0.30, 0.01), Vector3(0, 0.36, 0.126), pj_dark)
	for yy in [0.46, 0.37, 0.28]:
		_box(Vector3(0.018, 0.018, 0.012), Vector3(0.018, yy, 0.13),
			_mat(Color(0.78, 0.76, 0.68)))

	# Head: 4% too large on purpose.
	_head = _box(Vector3(0.23, 0.25, 0.22), Vector3(0, 0.69, 0.01), skin)
	_head.scale = Vector3(1.04, 1.04, 1.04)

	# Hair: a cap and a back panel. The head needs a silhouette.
	_box(Vector3(0.245, 0.075, 0.235), Vector3(0, 0.805, 0.005), hair, _head)
	_box(Vector3(0.220, 0.14, 0.040), Vector3(0, 0.70, -0.095), hair, _head)

	# Ears / eyebrows: the eyebrows are what make the face read at 320x180.
	_box(Vector3(0.050, 0.010, 0.014), Vector3(-0.052, 0.064, 0.118), hair, _head)
	_box(Vector3(0.050, 0.010, 0.014), Vector3(0.052, 0.079, 0.118), hair, _head)

	# Eyes: two black quads, one 1.5 cm higher (misaligned face trick). They
	# sit proud of the face, otherwise the head eats them at 320x180.
	var eye_l := _box(Vector3(0.040, 0.050, 0.02), Vector3(-0.052, 0.02, 0.118), dark, _head)
	var eye_r := _box(Vector3(0.040, 0.050, 0.02), Vector3(0.052, 0.035, 0.118), dark, _head)
	_eyes = [eye_l, eye_r]

	# Mouth, with the front right tooth missing.
	_box(Vector3(0.070, 0.020, 0.012), Vector3(0.004, -0.065, 0.118), dark, _head)
	_box(Vector3(0.018, 0.014, 0.008), Vector3(0.016, -0.063, 0.124),
		_mat(Color(0.80, 0.76, 0.68)), _head)

	# Arms: left 6% longer, sleeves cut at two different lengths. The jacket
	# is too big for him; it was probably someone else's.
	_box(Vector3(0.105, 0.22, 0.105), Vector3(-0.225, 0.44, 0.02), jacket)
	_box(Vector3(0.095, 0.20, 0.095), Vector3(-0.225, 0.245, 0.02), pj)
	_box(Vector3(0.085, 0.085, 0.09), Vector3(-0.225, 0.125, 0.03), skin)
	_box(Vector3(0.105, 0.19, 0.105), Vector3(0.225, 0.47, 0.02), jacket)
	_box(Vector3(0.095, 0.13, 0.095), Vector3(0.225, 0.315, 0.02), pj)
	_box(Vector3(0.085, 0.085, 0.09), Vector3(0.225, 0.23, 0.03), skin)

	# Legs folded, knees up.
	_box(Vector3(0.11, 0.15, 0.30), Vector3(-0.095, 0.13, 0.13), pj)
	_box(Vector3(0.11, 0.15, 0.30), Vector3(0.095, 0.13, 0.13), pj)
	_box(Vector3(0.105, 0.075, 0.13), Vector3(-0.095, 0.06, 0.30), skin)
	_box(Vector3(0.105, 0.075, 0.13), Vector3(0.095, 0.06, 0.30), skin)

	# Party hat: cone, two sizes too small, perched on one side of the head
	# instead of over the face. The first version was wide enough to hide the
	# eyes from a standing player, which killed the reveal.
	var hat_mi := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.055
	cone.height = 0.13
	hat_mi.mesh = cone
	hat_mi.material_override = hat
	hat_mi.position = Vector3(0.065, 0.845, -0.020)
	hat_mi.rotation_degrees = Vector3(-8, 0, -26)
	add_child(hat_mi)
	var stripe := _box(Vector3(0.050, 0.014, 0.050), Vector3(0.065, 0.815, -0.020),
		_mat(Color(0.84, 0.74, 0.52)))
	stripe.rotation_degrees = Vector3(-8, 0, -26)

	# Fake blob shadow (no shadow maps, ever)
	var blob := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.7, 0.7)
	blob.mesh = q
	blob.rotation_degrees = Vector3(-90, 0, 0)
	blob.position = Vector3(0, 0.02, 0)
	blob.material_override = _mat(Color(0, 0, 0, 0.45), true)
	add_child(blob)


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if parent != null:
		parent.add_child(mi)
	else:
		add_child(mi)
	return mi


func _mat(c: Color, transparent := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if following and follow_target != null:
		_follow(delta)
	if breathing:
		# tiny breathing scale on body — the wardrobe-gap tell
		var b := 1.0 + sin(_t * 1.7) * 0.02
		_body.scale = Vector3(1.0, b, 1.0)
		_head.position.y = 0.69 + sin(_t * 1.7) * 0.006
		# A head held a couple of degrees wrong. The player will read it as
		# "they are looking at me" long before they can say why.
		_head.rotation.z = sin(_t * 0.37) * 0.035
	# rare wrong blink: both eyes scale y to 0.1 for 120ms every ~4s
	_blink_t += delta
	if _blink_t > 4.0:
		_blink_t = 0.0
		_do_blink()


func _do_blink() -> void:
	# held-frame blink: freeze 120ms with eyes shut = cheap scare fuel.
	# Only the eyes, not the hair and mouth: the old version squashed every
	# child of the head, which made the whole face jump.
	for e in _eyes:
		if is_instance_valid(e):
			e.scale.y = 0.15
	await get_tree().create_timer(0.12).timeout
	for e in _eyes:
		if is_instance_valid(e):
			e.scale.y = 1.0


func reveal() -> void:
	visible = true


func follow(target: Node3D) -> void:
	follow_target = target
	following = true
	reveal()


func _follow(delta: float) -> void:
	var to: Vector3 = follow_target.global_position - global_position
	to.y = 0.0
	var d := to.length()
	if d > FOLLOW_DIST:
		var step: Vector3 = to.normalized() * minf(FOLLOW_SPEED * delta, d - FOLLOW_DIST * 0.6)
		global_position += step
		# face where we're going; lerp so the head doesn't snap
		var yaw := atan2(-to.x, -to.z)
		rotation.y = lerp_angle(rotation.y, yaw, minf(1.0, delta * 6.0))
	# little hurry-bob while moving, still breathing when still
	if d > FOLLOW_DIST + 0.2:
		_body.position.y = 0.35 + absf(sin(_t * 9.0)) * 0.03


func scare_pose() -> void:
	# Jumpscare frame: head snaps 12° + freeze handled by director
	_head.rotation_degrees = Vector3(-8, 12, 6)
	breathing = false
