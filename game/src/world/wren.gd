extends Node3D
## Wren — the child in the wardrobe. Part 1 version.
## ~14 boxes, unlit-ish StandardMaterial, deliberately wrong:
## head 4% too big, left arm 6% longer, eyes 2px off. docs/art-direction.md §4.1.
## No rig, no import, no PC load. Breathes via sin().

var _t := 0.0
var breathing := true
var _head: MeshInstance3D
var _body: MeshInstance3D
var _blink_t := 0.0


func _ready() -> void:
	_build()
	visible = false  # prologue reveals us


func _build() -> void:
	var skin := _mat(Color(0.82, 0.74, 0.66))
	var pj := _mat(Color(0.55, 0.62, 0.75))       # your pyjamas, but inside-out = paler
	var dark := _mat(Color(0.05, 0.05, 0.06))     # eyes: drawn wrong
	var hat := _mat(Color(0.75, 0.30, 0.32))     # party hat, too small
	var jacket := _mat(Color(0.45, 0.38, 0.30))

	# Body: sitting, knees up
	_body = _box(Vector3(0.34, 0.42, 0.24), Vector3(0, 0.35, 0), pj)

	# Head: 4% too large on purpose
	_head = _box(Vector3(0.24, 0.26, 0.23), Vector3(0, 0.70, 0.01), skin)
	_head.scale = Vector3(1.04, 1.04, 1.04)

	# Eyes: two black quads, one 2px higher (misaligned face trick)
	# NOTE: children of _head, so positions are LOCAL to head centre.
	_box(Vector3(0.035, 0.045, 0.01), Vector3(-0.055, 0.02, 0.115), dark, _head)
	_box(Vector3(0.035, 0.045, 0.01), Vector3(0.055, 0.035, 0.115), dark, _head)
	# Tooth gap: tiny dark notch for the missing front tooth
	_box(Vector3(0.03, 0.02, 0.01), Vector3(0.008, -0.10, 0.115), dark, _head)

	# Arms: left 6% longer, sleeves cut uneven
	var arm_l := _box(Vector3(0.09, 0.42, 0.09), Vector3(-0.23, 0.32, 0.02), jacket)
	arm_l.scale.y = 1.06
	_box(Vector3(0.09, 0.28, 0.09), Vector3(0.23, 0.32, 0.02), jacket)  # right short

	# Legs folded (knees up pose)
	_box(Vector3(0.11, 0.11, 0.34), Vector3(-0.09, 0.14, 0.12), pj)
	_box(Vector3(0.11, 0.11, 0.34), Vector3(0.09, 0.14, 0.12), pj)

	# Party hat: cone, two sizes too small, tilted
	var hat_mi := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.09
	cone.height = 0.16
	hat_mi.mesh = cone
	hat_mi.material_override = hat
	hat_mi.position = Vector3(0.03, 0.90, 0.0)
	hat_mi.rotation_degrees = Vector3(0, 0, -14)
	add_child(hat_mi)

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
	if breathing:
		# tiny breathing scale on body — the wardrobe-gap tell
		var b := 1.0 + sin(_t * 1.7) * 0.02
		_body.scale = Vector3(1.0, b, 1.0)
		_head.position.y = 0.70 + sin(_t * 1.7) * 0.006
	# rare wrong blink: both eyes scale y to 0.1 for 120ms every ~4s
	_blink_t += delta
	if _blink_t > 4.0:
		_blink_t = 0.0
		_do_blink()


func _do_blink() -> void:
	# held-frame blink: freeze 120ms with eyes shut = cheap scare fuel
	var eyes: Array[Node] = []
	for c in _head.get_children():
		eyes.append(c)
	for e in eyes:
		(e as Node3D).scale.y = 0.15
	await get_tree().create_timer(0.12).timeout
	for e in eyes:
		if is_instance_valid(e):
			(e as Node3D).scale.y = 1.0


func reveal() -> void:
	visible = true


func scare_pose() -> void:
	# Jumpscare frame: head snaps 12° + freeze handled by director
	_head.rotation_degrees = Vector3(-8, 12, 6)
	breathing = false
