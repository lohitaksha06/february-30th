extends Node3D
## The house. Four rooms, one floor.
##
## docs/prologue.md -- "a SMALL house: four rooms, one floor. This is
## deliberate and it is a performance strategy." See docs/tech-stack.md §5.
##
## Every room is within thirty seconds' walk of every other room. The player
## learns the whole layout in the first minute. Four rooms is roughly 2,000
## triangles of shell -- a large explorable house would be ~40,000 and a
## worse story.
##
## All of it is built here in code. No .tscn hand-editing.

const H := 2.6          # ceiling height
const T := 0.12          # wall thickness
const DOOR_W := 0.9      # doorway width
const DOOR_H := 2.05

# Room bounds. Bedrooms on one side, living/kitchen on the other, hallway
# between them.
const BED_X0 := 0.0
const BED_X1 := 3.6
const BED_Z0 := 0.0
const BED_Z1 := 3.4

const HALL_X0 := 3.6
const HALL_X1 := 4.8

const LIVE_X0 := 4.8
const LIVE_X1 := 9.0
const LIVE_Z0 := 0.0
const LIVE_Z1 := 4.2

const KITCHEN_Z0 := 4.2
const KITCHEN_Z1 := 6.4

const TOTAL_X0 := 0.0
const TOTAL_X1 := 9.0
const TOTAL_Z0 := 0.0
const TOTAL_Z1 := 6.4

const BED_COLOUR := Color(0.55, 0.53, 0.58)
const HALL_COLOUR := Color(0.66, 0.64, 0.60)
const LIVE_COLOUR := Color(0.72, 0.69, 0.63)
const FLOOR_COLOUR := Color(0.34, 0.30, 0.28)


func _ready() -> void:
	_floor()
	_bedroom()
	_hallway()
	_living_room()
	_kitchen()
	_lights()


func _add_wall(pos: Vector3, size: Vector3, col: Color) -> void:
	var wall_script: Script = preload("res://src/world/wall.gd")
	var w: Node3D = wall_script.new()
	w.set("width", size.x)
	w.set("height", size.y)
	w.set("thickness", size.z)
	w.set("colour", col)
	w.position = pos
	w.rotation.y = 0.0
	add_child(w)


## Floor and ceiling planes. Two quads each.
func _floor() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(TOTAL_X1 - TOTAL_X0, TOTAL_Z1 - TOTAL_Z0)
	pm.subdivide_width = 1
	pm.subdivide_depth = 1
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.position = Vector3((TOTAL_X0 + TOTAL_X1) * 0.5, 0.0, (TOTAL_Z0 + TOTAL_Z1) * 0.5)
	mi.material_override = _mat(FLOOR_COLOUR)
	add_child(mi)

	# Floor collision: one static box so the player never falls through.
	var fbody := StaticBody3D.new()
	fbody.position = Vector3((TOTAL_X0 + TOTAL_X1) * 0.5, -0.25, (TOTAL_Z0 + TOTAL_Z1) * 0.5)
	var fcol := CollisionShape3D.new()
	var fshape := BoxShape3D.new()
	fshape.size = Vector3(TOTAL_X1 - TOTAL_X0, 0.5, TOTAL_Z1 - TOTAL_Z0)
	fcol.shape = fshape
	fbody.add_child(fcol)
	add_child(fbody)

	var cm := BoxMesh.new()
	cm.size = Vector3(TOTAL_X1 - TOTAL_X0, 0.1, TOTAL_Z1 - TOTAL_Z0)
	var ceil := MeshInstance3D.new()
	ceil.mesh = cm
	ceil.position = Vector3((TOTAL_X0 + TOTAL_X1) * 0.5, H, (TOTAL_Z0 + TOTAL_Z1) * 0.5)
	ceil.material_override = _mat(Color(0.50, 0.49, 0.48))
	add_child(ceil)


func _bedroom() -> void:
	# Outer walls
	_add_wall(Vector3((BED_X0 + BED_X1) * 0.5, H * 0.5, BED_Z0 - T * 0.5),
		Vector3(BED_X1 - BED_X0, H, T), BED_COLOUR)
	_add_wall(Vector3(BED_X0 - T * 0.5, H * 0.5, (BED_Z0 + BED_Z1) * 0.5),
		Vector3(T, H, BED_Z1 - BED_Z0), BED_COLOUR)

	# Wall to the hallway, with a doorway
	_wall_with_door(
		Vector3(HALL_X0 - T * 0.5, 0.0, (BED_Z0 + BED_Z1) * 0.5),
		true, 1.4, BED_COLOUR)

	# The bed
	var bed := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.1, 0.45, 2.0)
	bed.mesh = bm
	bed.position = Vector3(0.85, 0.22, 2.1)
	bed.material_override = _mat(Color(0.72, 0.70, 0.68))
	add_child(bed)

	var mattress := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(1.06, 0.16, 1.9)
	mattress.mesh = mm
	mattress.position = Vector3(0.85, 0.52, 2.1)
	mattress.material_override = _mat(Color(0.78, 0.76, 0.74))
	add_child(mattress)

	# Pillow
	var pil := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.7, 0.14, 0.34)
	pil.mesh = pm
	pil.position = Vector3(0.85, 0.65, 3.0)
	pil.material_override = _mat(Color(0.86, 0.85, 0.83))
	add_child(pil)

	# Nightstand + the clock. The clock is the most important prop in the
	# game and it is a box with a label on it.
	var ns := MeshInstance3D.new()
	var nsm := BoxMesh.new()
	nsm.size = Vector3(0.42, 0.55, 0.42)
	ns.mesh = nsm
	ns.position = Vector3(1.85, 0.275, 2.95)
	ns.material_override = _mat(Color(0.50, 0.40, 0.32))
	add_child(ns)

	# Wardrobe. THE PROPPOINT OF THE WHOLE GAME. Nine feet tall.
	var wd := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(1.2, 2.7, 0.7)
	wd.mesh = wm
	wd.position = Vector3(3.0, 1.35, 0.55)
	wd.material_override = _mat(Color(0.42, 0.36, 0.31))
	add_child(wd)

	var wcol := CollisionShape3D.new()
	var wshape := BoxShape3D.new()
	wshape.size = wm.size
	wcol.shape = wshape
	var wbody := StaticBody3D.new()
	wbody.position = wd.position
	wbody.add_child(wcol)
	add_child(wbody)

	# The wardrobe door -- a child node, so it can open. This is the door the
	# player pushes Wren through.
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.55, 2.55, 0.08)
	door.mesh = dm
	door.name = "WardrobeDoor"
	door.position = Vector3(0.0, 1.275, 0.38)
	wd.add_child(door)


func _hallway() -> void:
	_add_wall(Vector3((HALL_X0 + HALL_X1) * 0.5, H * 0.5, TOTAL_Z0 - T * 0.5),
		Vector3(HALL_X1 - HALL_X0, H, T), HALL_COLOUR)
	# Wall to the living room, doorway at z ~ 2.0
	_wall_with_door(
		Vector3(LIVE_X0 - T * 0.5, 0.0, 2.0),
		true, 2.9, HALL_COLOUR)

	# Your mother's door. Closed. She is behind it and never comes out.
	_add_wall(Vector3((HALL_X0 + HALL_X1) * 0.5, H * 0.5, 4.6),
		Vector3(HALL_X1 - HALL_X0, H, T), HALL_COLOUR)


func _living_room() -> void:
	_add_wall(Vector3(TOTAL_X1 + T * 0.5, H * 0.5, (LIVE_Z0 + LIVE_Z1) * 0.5),
		Vector3(T, H, LIVE_Z1 - LIVE_Z0), LIVE_COLOUR)
	# Wall to the kitchen
	_wall_with_door(Vector3((LIVE_X0 + TOTAL_X1) * 0.5, 0.0, LIVE_Z1),
		false, 1.2, LIVE_COLOUR)

	# THE CAKE TABLE. This is the last safe table and at the end of the game
	# the party happens on it again. docs/scope.md.
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(1.6, 0.08, 0.95)
	top.mesh = tm
	top.position = Vector3(6.9, 0.74, 1.6)
	top.material_override = _mat(Color(0.55, 0.42, 0.30))
	add_child(top)

	for sx in [-0.7, 0.7]:
		for sz in [-0.38, 0.38]:
			var leg := MeshInstance3D.new()
			var lm := BoxMesh.new()
			lm.size = Vector3(0.08, 0.74, 0.08)
			leg.mesh = lm
			leg.position = Vector3(6.9 + sx, 0.37, 1.6 + sz)
			leg.material_override = _mat(Color(0.55, 0.42, 0.30))
			add_child(leg)

	# One chair, pulled out.
	var chair := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.42, 0.05, 0.42)
	chair.mesh = cm
	chair.position = Vector3(6.9, 0.46, 2.5)
	chair.material_override = _mat(Color(0.50, 0.44, 0.38))
	add_child(chair)

	# The cake itself.
	var cake := MeshInstance3D.new()
	var ckm := CylinderMesh.new()
	ckm.top_radius = 0.16
	ckm.bottom_radius = 0.16
	ckm.height = 0.14
	cake.mesh = ckm
	cake.position = Vector3(6.9, 0.85, 1.6)
	cake.material_override = _mat(Color(0.94, 0.86, 0.80))
	add_child(cake)

	# Eleven candles. Counted twice, by the mother.
	for i in range(11):
		var c := MeshInstance3D.new()
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = 0.012
		cmesh.bottom_radius = 0.012
		cmesh.height = 0.10
		c.mesh = cmesh
		var ang := TAU * i / 11.0
		c.position = Vector3(6.9 + cos(ang) * 0.10, 0.96, 1.6 + sin(ang) * 0.10)
		c.material_override = _mat(Color(0.95, 0.92, 0.75))
		add_child(c)

	# One plate, one fork, one glass. It is nobody's birthday but yours.
	var plate := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.11
	pm.bottom_radius = 0.09
	pm.height = 0.02
	plate.mesh = pm
	plate.position = Vector3(6.35, 0.80, 1.75)
	plate.material_override = _mat(Color(0.90, 0.89, 0.87))
	add_child(plate)


func _kitchen() -> void:
	_add_wall(Vector3((LIVE_X0 + TOTAL_X1) * 0.5, H * 0.5, TOTAL_Z1 + T * 0.5),
		Vector3(TOTAL_X1 - LIVE_X0, H, T), Color(0.66, 0.66, 0.63))

	# Cold. Lights off. Plates still in the dishwasher -- it is past midnight
	# and she has not cleaned up, because she was waiting for you.
	var counter := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(2.2, 0.85, 0.6)
	counter.mesh = cm
	counter.position = Vector3(7.2, 0.425, 6.05)
	counter.material_override = _mat(Color(0.60, 0.60, 0.58))
	add_child(counter)


## A wall with a doorway punched through it.
##
## Built as two segments plus a lintel rather than as geometry with a hole, so
## it is 4 boxes instead of a boolean operation. No CSG, no triangulation
## surprises.
func _wall_with_door(origin: Vector3, along_z: bool, door_pos_along: float, col: Color) -> void:
	var total := (LIVE_Z1 - LIVE_Z0) if along_z else (TOTAL_X1 - TOTAL_X0)
	if along_z == false:
		total = TOTAL_Z1 - TOTAL_Z0
		total = (BED_Z1 - BED_Z0) if absf(origin.z - 1.7) < 0.1 else (TOTAL_Z1 - TOTAL_Z0)

	# Simpler: derive from the two sides given.
	var span := 0.0
	if along_z:
		span = 3.4 if absf(origin.x - 3.6) < 0.1 else (TOTAL_Z1 - TOTAL_Z0)
	else:
		span = 4.2 if absf(origin.z - 4.2) < 0.1 else (BED_Z1 - BED_Z0)

	var dpos := door_pos_along
	var seg := (span - DOOR_W) * 0.5
	var seg_size := Vector3(T, H, seg) if along_z else Vector3(seg, H, T)

	var cx := origin.x
	var cz := origin.z

	# segment before the door
	var a := Vector3(cx, H * 0.5, cz - span * 0.5 + seg * 0.5)
	if not along_z:
		a = Vector3(cx - span * 0.5 + seg * 0.5, H * 0.5, cz)
	_add_wall(a, seg_size, col)

	# segment after the door
	var b := Vector3(cx, H * 0.5, cz + span * 0.5 - seg * 0.5)
	if not along_z:
		b = Vector3(cx + span * 0.5 - seg * 0.5, H * 0.5, cz)
	_add_wall(b, seg_size, col)

	# lintel above the door
	var lintel := Vector3(T, H - DOOR_H, DOOR_W) if along_z else Vector3(DOOR_W, H - DOOR_H, T)
	var l := Vector3(cx, DOOR_H + (H - DOOR_H) * 0.5, cz)
	if not along_z:
		l = Vector3(cx + dpos, DOOR_H + (H - DOOR_H) * 0.5, cz)
	_add_wall(l, lintel, col)


## Two lights only. One streetlight through the bedroom window, one dim
## ambient. Indoors there is NO directional light -- the flashlight is the only
## thing that reveals a room. docs/art-direction.md §7.
func _lights() -> void:
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.17, 0.22)
	env.ambient_light_energy = 0.30
	# No SSAO, no glow, no fog volumetrics, no TAA. Every one of those is a
	# frame-time cost we cannot afford on a 2017 iGPU. docs/tech-stack.md §6.
	amb.environment = env
	add_child(amb)

	# The streetlight. Cold blue, moving very slightly, as if a car is passing.
	# It is the last warm-neutral thing in the game and it is gone in Act I.
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.62, 0.70, 0.92)
	sun.light_energy = 0.55
	sun.shadow_enabled = false   # zero shadow maps. docs/art-direction.md §7
	sun.rotation_degrees = Vector3(-38.0, 145.0, 0.0)
	sun.position = Vector3(4.0, 4.0, 1.0)
	add_child(sun)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m