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
##
## Playtest fix: the old shell left the south and east sides of the bedroom /
## living room open, so the player could walk off the floor and fall out of the
## world. `_seal_shell()` closes the whole footprint, and `_wall_with_door()`
## now places its lintel over the actual gap instead of an offset position.
##
## Atmosphere pass: the house is now lit like a house at 11:59 PM rather than a
## greybox. Ambient is almost black, every room has one warm practical light,
## cold streetlight comes through the bedroom window, and the only shadow map
## in the game is the flashlight (docs/art-direction.md §7 allows exactly one).
## Colour is deliberate: blue bedroom, amber hall, peach birthday room, sick
## green kitchen. The warm rooms are safe. The cold rooms are not.

const H := 2.6            # ceiling height
const T := 0.12           # wall thickness
const DOOR_W := 0.9       # doorway width
const DOOR_H := 2.05

# Room bounds. Bedrooms on one side, living/kitchen on the other, hallway
# between them.
const BED_X0 := 0.0
const BED_X1 := 3.6
const BED_Z0 := 0.0
const BED_Z1 := 3.4

const HALL_X0 := 3.6
const HALL_X1 := 4.8
const HALL_Z1 := 4.6

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

# A warm, lived-in palette, pushed darker so the practicals do the work.
const BED_COLOUR := Color(0.29, 0.35, 0.47)     # dusty blue
const BED_STRIPE := Color(0.33, 0.40, 0.52)
const HALL_COLOUR := Color(0.50, 0.42, 0.32)    # warm brown
const LIVE_COLOUR := Color(0.60, 0.46, 0.34)    # peach
const KITCH_COLOUR := Color(0.36, 0.46, 0.40)   # mint
const FLOOR_COLOUR := Color(0.21, 0.14, 0.10)   # dark wood
const CEIL_COLOUR := Color(0.36, 0.34, 0.32)
const VOID_COLOUR := Color(0.30, 0.28, 0.26)
const TRIM := Color(0.64, 0.60, 0.52)
const DADO := Color(0.39, 0.31, 0.23)           # wainscot panel
const DADO_LIGHT := Color(0.46, 0.37, 0.27)

## The streetlight pool in the bedroom. Drifts in _process so the wake line
## ("the streetlight moving across the ceiling") is literal.
var _street_spot: SpotLight3D
## The bare hallway bulb, the living room light, the kitchen tube. Kept so
## `set_midnight()` can take the warm light out of the house on cue.
var _hall_omni: OmniLight3D
var _hall_far: OmniLight3D
var _living_omni: OmniLight3D
var _lamp_omni: OmniLight3D
var _floor_lamp: OmniLight3D
var _fluor: OmniLight3D
var _leak_omni: OmniLight3D
var _door_hinge: Node3D

## Set by the prologue when the knocking starts: the wardrobe door breathes.
var _dread := false
var _midnight := false


func _ready() -> void:
	_floor()
	_bedroom()
	_hallway()
	_living_room()
	_kitchen()
	_seal_shell()
	_decor()
	_skirting()
	_door_trim_all()
	_lights()


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001

	if _street_spot != null:
		var base := 1.15 if _midnight else 2.45
		_street_spot.light_energy = base + sin(t * 0.7) * 0.22
		_street_spot.position.x = 1.25 + sin(t * 0.21) * 0.14

	# The wardrobe door is not flush. It moves about a centimetre, slowly,
	# like something on the other side is breathing. docs/prologue.md Beat 5.
	if _dread and _door_hinge != null:
		_door_hinge.rotation.y = -0.045 + sin(t * 1.15) * 0.016

	# One fluorescent tube, occasionally failing. Not a strobe: a house sound.
	if _fluor != null:
		var cycle := fmod(t, 11.0)
		var f := 1.0
		if cycle > 9.6 and cycle < 9.75:
			f = 0.15
		elif cycle > 10.1 and cycle < 10.2:
			f = 0.35
		_fluor.light_energy = (0.0 if _midnight else 0.55) * f

	# The hallway bulb is old. It drops out at a different, slower rate than
	# the kitchen tube, and the corridor goes black for a quarter of a second.
	if _hall_omni != null:
		var hc := fmod(t, 13.0)
		var hf := 1.0
		if hc > 11.20 and hc < 11.28:
			hf = 0.30
		elif hc > 11.44 and hc < 11.50:
			hf = 0.55
		_hall_omni.light_energy = 0.0 if _midnight else 0.62 * hf

	# Light under Mum's door. Never quite steady.
	if _leak_omni != null:
		_leak_omni.light_energy = 0.22 + sin(t * 0.37) * 0.03


## Called by the prologue when the knocks begin.
func set_wardrobe_dread(on: bool) -> void:
	_dread = on
	if not on and _door_hinge != null:
		_door_hinge.rotation.y = 0.0


## Called when the clock turns 12:00. The warm house goes out; only the cold
## streetlight and the door leak are left. Cheap, and the whole mood changes.
func set_midnight(on: bool) -> void:
	_midnight = on
	var target := 0.04 if on else -1.0
	for l in [_hall_omni, _hall_far, _living_omni, _lamp_omni, _floor_lamp]:
		if l == null:
			continue
		var light := l as OmniLight3D
		var base := float(light.get_meta("base_energy", light.light_energy))
		var tw := create_tween()
		tw.tween_property(light, "light_energy", target if target >= 0.0 else base, 2.2)


# ---------------------------------------------------------------- shell

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
	mi.position = Vector3((TOTAL_X0 + TOTAL_X1) * 0.5, 0.0,
		(TOTAL_Z0 + TOTAL_Z1) * 0.5)
	mi.material_override = _mat(FLOOR_COLOUR)
	add_child(mi)

	# Floor collision: one static box so the player never falls through.
	var fbody := StaticBody3D.new()
	fbody.position = Vector3((TOTAL_X0 + TOTAL_X1) * 0.5, -0.25,
		(TOTAL_Z0 + TOTAL_Z1) * 0.5)
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
	ceil.position = Vector3((TOTAL_X0 + TOTAL_X1) * 0.5, H,
		(TOTAL_Z0 + TOTAL_Z1) * 0.5)
	ceil.material_override = _mat(CEIL_COLOUR)
	add_child(ceil)

	# Floorboards: long, slightly uneven strips. Ten thin boxes is enough to
	# stop the floor reading as one flat rectangle under a torch.
	var board := Color(0.16, 0.10, 0.075)
	for i in range(18):
		var z := 0.18 + i * 0.36
		_box(Vector3((TOTAL_X0 + TOTAL_X1) * 0.5, 0.004, z),
			Vector3(TOTAL_X1 - TOTAL_X0, 0.006, 0.012), board)


func _seal_shell() -> void:
	# The missing outer pieces. Interior walls keep their room colour; these
	# are only ever seen from the sealed void, so a neutral plaster is fine.
	# South of the bedroom (x 0..4.8).
	_add_wall(Vector3((TOTAL_X0 + LIVE_X0) * 0.5, H * 0.5, TOTAL_Z1 + T * 0.5),
		Vector3(LIVE_X0 - TOTAL_X0, H, T), VOID_COLOUR)
	# West of the void (z 3.4..6.4).
	_add_wall(Vector3(TOTAL_X0 - T * 0.5, H * 0.5, (BED_Z1 + TOTAL_Z1) * 0.5),
		Vector3(T, H, TOTAL_Z1 - BED_Z1), VOID_COLOUR)


## A wall with a doorway punched through it.
##
## `along_z` means the wall runs along Z (a wall at a fixed X); otherwise it
## runs along X. `door_center` is the centre of the gap in the same axis and
## `span` is the full wall length. The old version guessed spans from the
## origin and placed the lintel at an offset, which left holes above doors.
func _wall_with_door(origin: Vector3, along_z: bool, door_center: float,
		span: float, col: Color) -> void:
	var lo := (origin.z - span * 0.5) if along_z else (origin.x - span * 0.5)
	var hi := (origin.z + span * 0.5) if along_z else (origin.x + span * 0.5)
	var dc := clampf(door_center, lo + DOOR_W * 0.5, hi - DOOR_W * 0.5)
	var d0 := dc - DOOR_W * 0.5
	var d1 := dc + DOOR_W * 0.5

	if d0 > lo + 0.001:
		var seg := d0 - lo
		if along_z:
			_add_wall(Vector3(origin.x, H * 0.5, lo + seg * 0.5), Vector3(T, H, seg), col)
		else:
			_add_wall(Vector3(lo + seg * 0.5, H * 0.5, origin.z), Vector3(seg, H, T), col)

	if hi > d1 + 0.001:
		var seg := hi - d1
		if along_z:
			_add_wall(Vector3(origin.x, H * 0.5, d1 + seg * 0.5), Vector3(T, H, seg), col)
		else:
			_add_wall(Vector3(d1 + seg * 0.5, H * 0.5, origin.z), Vector3(seg, H, T), col)

	# Lintel above the door, exactly over the gap.
	var lintel_y := DOOR_H + (H - DOOR_H) * 0.5
	if along_z:
		_add_wall(Vector3(origin.x, lintel_y, dc), Vector3(T, H - DOOR_H, DOOR_W), col)
	else:
		_add_wall(Vector3(dc, lintel_y, origin.z), Vector3(DOOR_W, H - DOOR_H, T), col)


func _bedroom() -> void:
	# Outer walls
	_add_wall(Vector3((BED_X0 + BED_X1) * 0.5, H * 0.5, BED_Z0 - T * 0.5),
		Vector3(BED_X1 - BED_X0, H, T), BED_COLOUR)
	_add_wall(Vector3(BED_X0 - T * 0.5, H * 0.5, (BED_Z0 + BED_Z1) * 0.5),
		Vector3(T, H, BED_Z1 - BED_Z0), BED_COLOUR)
	# South wall: this used to be absent, which is how the player walked out
	# of the bedroom into the void.
	_add_wall(Vector3((BED_X0 + BED_X1) * 0.5, H * 0.5, BED_Z1 + T * 0.5),
		Vector3(BED_X1 - BED_X0, H, T), BED_COLOUR)

	# Wall to the hallway, with a doorway.
	_wall_with_door(
		Vector3(HALL_X0 - T * 0.5, 0.0, (BED_Z0 + BED_Z1) * 0.5),
		true, 1.7, BED_Z1 - BED_Z0, BED_COLOUR)

	# Striped wallpaper. Eight thin raised strips on the west wall and four on
	# the north wall; no texture, no import, and the room stops being a box.
	for i in range(8):
		var z := 0.33 + i * 0.40
		_box(Vector3(0.068, 1.34, z), Vector3(0.014, 2.30, 0.055),
			BED_STRIPE)
	for i in range(7):
		var x := 0.30 + i * 0.50
		_box(Vector3(x, 1.34, 0.068), Vector3(0.055, 2.30, 0.014),
			BED_STRIPE)

	# Cornice. A thin band at the ceiling line makes the room feel finished.
	_box(Vector3(BED_X1 * 0.5, H - 0.07, 0.07), Vector3(BED_X1, 0.09, 0.05), TRIM)
	_box(Vector3(BED_X1 * 0.5, H - 0.07, BED_Z1 - 0.07), Vector3(BED_X1, 0.09, 0.05), TRIM)
	_box(Vector3(0.07, H - 0.07, BED_Z1 * 0.5), Vector3(0.05, 0.09, BED_Z1), TRIM)
	_box(Vector3(BED_X1 - 0.07, H - 0.07, BED_Z1 * 0.5), Vector3(0.05, 0.09, BED_Z1), TRIM)

	# The bed. A frame, a mattress, a duvet, a headboard. The old single box
	# read as a slab; the three-layer build reads as a bed in torchlight.
	_box(Vector3(0.85, 0.20, 2.10), Vector3(1.12, 0.40, 2.00), Color(0.30, 0.20, 0.14))
	_box(Vector3(0.85, 0.44, 2.10), Vector3(1.06, 0.16, 1.92), Color(0.72, 0.69, 0.64))
	# Duvet, folded back at the pillow end.
	_box(Vector3(0.85, 0.545, 2.30), Vector3(1.06, 0.06, 1.52), Color(0.20, 0.31, 0.46))
	_box(Vector3(0.85, 0.585, 2.55), Vector3(0.94, 0.045, 0.32), Color(0.30, 0.42, 0.58))
	# Pillows.
	_box(Vector3(0.85, 0.615, 2.95), Vector3(0.68, 0.13, 0.34), Color(0.86, 0.83, 0.76))
	_box(Vector3(0.85, 0.66, 2.78), Vector3(0.58, 0.10, 0.28), Color(0.90, 0.87, 0.80))
	# Headboard and footboard.
	_box(Vector3(0.85, 0.62, 3.13), Vector3(1.20, 1.24, 0.10), Color(0.28, 0.18, 0.13))
	_box(Vector3(0.85, 0.36, 1.06), Vector3(1.20, 0.72, 0.09), Color(0.28, 0.18, 0.13))
	var bed_body := StaticBody3D.new()
	var bed_col := CollisionShape3D.new()
	var bed_shape := BoxShape3D.new()
	bed_shape.size = Vector3(1.12, 0.60, 2.00)
	bed_col.shape = bed_shape
	bed_body.position = Vector3(0.85, 0.30, 2.10)
	bed_body.add_child(bed_col)
	add_child(bed_body)
	var bed := _box(Vector3(0.85, 0.22, 2.1), Vector3(1.1, 0.45, 2.0),
		Color(0.72, 0.70, 0.68))
	bed.name = "Bed"

	# Nightstand + the clock. The clock is the most important prop in the
	# game and it is a box with a label on it.
	_box(Vector3(1.85, 0.275, 2.95), Vector3(0.46, 0.55, 0.44), Color(0.42, 0.31, 0.22))
	_box(Vector3(1.85, 0.56, 2.95), Vector3(0.50, 0.03, 0.48), Color(0.50, 0.38, 0.27))
	_box(Vector3(1.85, 0.18, 3.17), Vector3(0.34, 0.02, 0.02), Color(0.20, 0.14, 0.10))
	_collider(Vector3(1.85, 0.28, 2.95), Vector3(0.46, 0.56, 0.44))

	# Wardrobe. THE PROPPOINT OF THE WHOLE GAME. Nine feet tall.
	var wd := _box(Vector3(3.0, 1.35, 0.55), Vector3(1.2, 2.7, 0.7),
		Color(0.31, 0.24, 0.18))
	wd.name = "Wardrobe"

	var wcol := CollisionShape3D.new()
	var wshape := BoxShape3D.new()
	wshape.size = Vector3(1.2, 2.7, 0.7)
	wcol.shape = wshape
	var wbody := StaticBody3D.new()
	wbody.position = wd.position
	wbody.add_child(wcol)
	add_child(wbody)

	# Plinth and cornice. The wardrobe is 2.7 m in a 2.6 m room: slightly too
	# tall is the whole character. docs/art-direction.md §4.1.
	_box(Vector3(3.0, 0.05, 0.55), Vector3(1.28, 0.10, 0.78), Color(0.22, 0.16, 0.12))
	_box(Vector3(3.0, 2.73, 0.55), Vector3(1.30, 0.10, 0.80), Color(0.36, 0.28, 0.21))
	# Front side stiles.
	_box(Vector3(2.43, 1.38, 0.905), Vector3(0.06, 2.58, 0.04), Color(0.40, 0.31, 0.23))
	_box(Vector3(3.46, 1.38, 0.905), Vector3(0.06, 2.58, 0.04), Color(0.40, 0.31, 0.23))

	# The wardrobe door -- hinged on its right edge so it swings open toward the
	# east wall, not across the player's line of sight to Wren. This is the
	# door the player pushes Wren through.
	var hinge := Node3D.new()
	hinge.name = "WardrobeDoor"
	hinge.position = Vector3(0.6, 0.0, 0.38)
	wd.add_child(hinge)
	_door_hinge = hinge
	_box(Vector3(-0.59, 0.0, 0.0), Vector3(1.18, 2.55, 0.06),
		Color(0.35, 0.27, 0.20), 0.0, hinge)
	# Raised panels on the door.
	_box(Vector3(-0.59, 0.62, 0.04), Vector3(0.86, 0.86, 0.02),
		Color(0.40, 0.31, 0.23), 0.0, hinge)
	_box(Vector3(-0.59, -0.52, 0.04), Vector3(0.86, 0.94, 0.02),
		Color(0.40, 0.31, 0.23), 0.0, hinge)
	# Brass handle, opposite the hinge.
	_sphere(Vector3(-1.02, 0.0, 0.06), 0.035, Color(0.70, 0.56, 0.26), hinge)


func _hallway() -> void:
	_add_wall(Vector3((HALL_X0 + HALL_X1) * 0.5, H * 0.5, TOTAL_Z0 - T * 0.5),
		Vector3(HALL_X1 - HALL_X0, H, T), HALL_COLOUR)
	# West side below the bedroom (z 3.4..4.6). Without this the hallway
	# opened into the sealed void behind the bedroom.
	_add_wall(Vector3(HALL_X0 - T * 0.5, H * 0.5, (BED_Z1 + HALL_Z1) * 0.5),
		Vector3(T, H, HALL_Z1 - BED_Z1), HALL_COLOUR)
	# Wall to the living room, doorway at z ~ 2.1.
	_wall_with_door(
		Vector3(LIVE_X0 - T * 0.5, 0.0, (LIVE_Z0 + LIVE_Z1) * 0.5),
		true, 2.1, LIVE_Z1 - LIVE_Z0, HALL_COLOUR)

	# Your mother's door. Closed. She is behind it and never comes out.
	_add_wall(Vector3((HALL_X0 + HALL_X1) * 0.5, H * 0.5, HALL_Z1 + T * 0.5),
		Vector3(HALL_X1 - HALL_X0, H, T), HALL_COLOUR)
	# The door itself: dark wood, a brass knob, and a warm line of light
	# underneath. The light is the first thing the game says about her.
	_box(Vector3(4.2, 1.0, HALL_Z1 - 0.025), Vector3(0.82, 2.04, 0.05),
		Color(0.24, 0.14, 0.09))
	_box(Vector3(4.2, 1.30, HALL_Z1 - 0.055), Vector3(0.56, 0.62, 0.02),
		Color(0.28, 0.17, 0.11))
	_box(Vector3(4.2, 0.52, HALL_Z1 - 0.055), Vector3(0.56, 0.76, 0.02),
		Color(0.28, 0.17, 0.11))
	_sphere(Vector3(4.53, 1.02, HALL_Z1 - 0.075), 0.038, Color(0.78, 0.60, 0.24))
	var leak := _glow_box(Vector3(4.2, 0.012, HALL_Z1 - 0.045),
		Vector3(0.84, 0.018, 0.035), Color(1.0, 0.74, 0.40))
	leak.name = "MumDoorLeak"

	# Wainscot: a darker dado panel and a chair rail. Every hallway in every
	# house in this register has one.
	_wainscot_x(0.075, 3.68, 4.73, HALL_COLOUR)
	_wainscot_x(HALL_Z1 - 0.075, 3.68, 3.74, HALL_COLOUR)
	_wainscot_z(HALL_X0 + 0.075, 0.075, 1.23, HALL_COLOUR)
	_wainscot_z(HALL_X0 + 0.075, 2.17, HALL_Z1 - 0.08, HALL_COLOUR)
	_wainscot_z(HALL_X1 - 0.075, 0.075, 1.63, HALL_COLOUR)
	_wainscot_z(HALL_X1 - 0.075, 2.57, HALL_Z1 - 0.08, HALL_COLOUR)

	# Roses on the ceiling line.
	_box(Vector3(4.2, H - 0.07, 0.07), Vector3(1.2, 0.09, 0.05), TRIM)
	_box(Vector3(4.2, H - 0.07, HALL_Z1 - 0.07), Vector3(1.2, 0.09, 0.05), TRIM)


func _living_room() -> void:
	# North and east outer walls. The north one used to be missing entirely,
	# so the player could walk straight out of the living room at z < 0.
	_add_wall(Vector3((LIVE_X0 + TOTAL_X1) * 0.5, H * 0.5, TOTAL_Z0 - T * 0.5),
		Vector3(TOTAL_X1 - LIVE_X0, H, T), LIVE_COLOUR)
	_add_wall(Vector3(TOTAL_X1 + T * 0.5, H * 0.5, (LIVE_Z0 + LIVE_Z1) * 0.5),
		Vector3(T, H, LIVE_Z1 - LIVE_Z0), LIVE_COLOUR)
	# Wall to the kitchen
	_wall_with_door(Vector3((LIVE_X0 + TOTAL_X1) * 0.5, 0.0, LIVE_Z1),
		false, 8.1, LIVE_X1 - LIVE_X0, LIVE_COLOUR)

	# Wainscot around the room. The birthday room is the warmest room in the
	# game and the only one with a pattern on the wall.
	_wainscot_x(0.075, 4.87, 8.93, LIVE_COLOUR)
	_wainscot_z(LIVE_X0 + 0.075, 0.075, 1.63, LIVE_COLOUR)
	_wainscot_z(LIVE_X0 + 0.075, 2.57, LIVE_Z1 - 0.08, LIVE_COLOUR)
	_wainscot_z(TOTAL_X1 - 0.075, 0.075, LIVE_Z1 - 0.08, LIVE_COLOUR)
	_wainscot_x(LIVE_Z1 - 0.075, 4.87, 7.62, LIVE_COLOUR)
	_wainscot_x(LIVE_Z1 - 0.075, 8.58, 8.93, LIVE_COLOUR)

	_box(Vector3(6.9, H - 0.07, 0.07), Vector3(4.2, 0.09, 0.05), TRIM)
	_box(Vector3(6.9, H - 0.07, LIVE_Z1 - 0.07), Vector3(4.2, 0.09, 0.05), TRIM)
	_box(Vector3(4.87, H - 0.07, 2.1), Vector3(0.05, 0.09, 4.2), TRIM)
	_box(Vector3(8.93, H - 0.07, 2.1), Vector3(0.05, 0.09, 4.2), TRIM)

	# THE CAKE TABLE. This is the last safe table and at the end of the game
	# the party happens on it again. docs/scope.md.
	_box(Vector3(6.9, 0.74, 1.6), Vector3(1.6, 0.08, 0.95), Color(0.46, 0.33, 0.22))
	for sx in [-0.7, 0.7]:
		for sz in [-0.38, 0.38]:
			_box(Vector3(6.9 + sx, 0.37, 1.6 + sz), Vector3(0.08, 0.74, 0.08),
				Color(0.38, 0.26, 0.17))
	_collider(Vector3(6.9, 0.40, 1.6), Vector3(1.6, 0.80, 0.95))

	# Tablecloth. Warm cream, with a dark red runner. The old blue cloth was
	# the brightest surface in the house and pulled the eye off the cake.
	_box(Vector3(6.9, 0.795, 1.6), Vector3(1.72, 0.02, 1.06), Color(0.62, 0.56, 0.45))
	for sx in [-0.84, 0.84]:
		_box(Vector3(6.9 + sx, 0.50, 1.6), Vector3(0.02, 0.58, 1.06), Color(0.55, 0.49, 0.39))
	for sz in [-0.51, 0.51]:
		_box(Vector3(6.9, 0.50, 1.6 + sz), Vector3(1.72, 0.58, 0.02), Color(0.55, 0.49, 0.39))
	_box(Vector3(6.9, 0.808, 1.6), Vector3(0.44, 0.006, 1.06), Color(0.36, 0.12, 0.14))

	# One chair, pulled out.
	_box(Vector3(6.9, 0.46, 2.55), Vector3(0.42, 0.05, 0.42), Color(0.44, 0.32, 0.22))
	for sx in [-0.17, 0.17]:
		for sz in [-0.17, 0.17]:
			_box(Vector3(6.9 + sx, 0.23, 2.55 + sz), Vector3(0.05, 0.46, 0.05),
				Color(0.36, 0.25, 0.17))
	_box(Vector3(6.9, 0.72, 2.74), Vector3(0.42, 0.48, 0.05), Color(0.44, 0.32, 0.22))

	# The cake itself: two tiers, white frosting, a thin pink band.
	var cake := MeshInstance3D.new()
	var ckm := CylinderMesh.new()
	ckm.top_radius = 0.18
	ckm.bottom_radius = 0.18
	ckm.height = 0.15
	cake.mesh = ckm
	cake.position = Vector3(6.9, 0.875, 1.6)
	cake.material_override = _mat(Color(0.93, 0.87, 0.80))
	add_child(cake)
	var icing := MeshInstance3D.new()
	var icm := CylinderMesh.new()
	icm.top_radius = 0.185
	icm.bottom_radius = 0.185
	icm.height = 0.035
	icing.mesh = icm
	icing.position = Vector3(6.9, 0.965, 1.6)
	icing.material_override = _mat(Color(0.96, 0.78, 0.82))
	add_child(icing)
	# Cake stand.
	_cyl(Vector3(6.9, 0.805, 1.6), 0.20, 0.17, 0.025, Color(0.74, 0.72, 0.66))
	_cyl(Vector3(6.9, 0.79, 1.6), 0.06, 0.09, 0.02, Color(0.68, 0.66, 0.60))

	# Eleven candles. Counted twice, by the mother.
	for i in range(11):
		var c := MeshInstance3D.new()
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = 0.012
		cmesh.bottom_radius = 0.012
		cmesh.height = 0.10
		c.mesh = cmesh
		var ang := TAU * i / 11.0
		c.position = Vector3(6.9 + cos(ang) * 0.11, 1.02, 1.6 + sin(ang) * 0.11)
		c.material_override = _mat(Color(0.94, 0.90, 0.72))
		add_child(c)

	# One place setting: a flat plate, a fork, a glass. It used to be a fat
	# disc that read as a second cake in the capture, so it is now smaller,
	# further from the cake, and not white.
	_cyl(Vector3(6.42, 0.812, 1.96), 0.095, 0.085, 0.010, Color(0.74, 0.73, 0.70))
	_cyl(Vector3(6.42, 0.820, 1.96), 0.062, 0.075, 0.005, Color(0.62, 0.61, 0.59))
	_box(Vector3(6.28, 0.815, 1.96), Vector3(0.10, 0.005, 0.010), Color(0.60, 0.60, 0.62))
	_box(Vector3(6.245, 0.815, 1.96), Vector3(0.03, 0.005, 0.028), Color(0.60, 0.60, 0.62))
	_cyl(Vector3(6.56, 0.865, 1.93), 0.030, 0.024, 0.10, Color(0.52, 0.60, 0.66))

	# Presents, with ribbon.
	_box(Vector3(5.95, 0.12, 0.95), Vector3(0.35, 0.24, 0.35), Color(0.58, 0.14, 0.18))
	_box(Vector3(5.95, 0.25, 0.95), Vector3(0.37, 0.02, 0.05), Color(0.86, 0.75, 0.38))
	_box(Vector3(5.95, 0.25, 0.95), Vector3(0.05, 0.02, 0.37), Color(0.86, 0.75, 0.38))
	_box(Vector3(7.95, 0.10, 0.85), Vector3(0.30, 0.20, 0.30), Color(0.16, 0.34, 0.58))
	_box(Vector3(7.95, 0.21, 0.85), Vector3(0.05, 0.02, 0.32), Color(0.86, 0.75, 0.38))
	_box(Vector3(6.25, 0.08, 2.65), Vector3(0.26, 0.16, 0.26), Color(0.24, 0.50, 0.30))

	# Wall art + the banner. Label3D faces +Z, into the room.
	_box(Vector3(8.98, 1.75, 1.1), Vector3(0.02, 0.55, 0.75), Color(0.62, 0.30, 0.22))
	_box(Vector3(8.97, 1.75, 1.1), Vector3(0.02, 0.42, 0.62), Color(0.78, 0.70, 0.54))
	# A tiny landscape inside the frame: sky, ground, one red sun.
	_box(Vector3(8.958, 1.80, 1.1), Vector3(0.01, 0.20, 0.56), Color(0.38, 0.50, 0.62))
	_box(Vector3(8.958, 1.66, 1.1), Vector3(0.01, 0.14, 0.56), Color(0.22, 0.32, 0.22))
	_box(Vector3(8.950, 1.84, 1.28), Vector3(0.01, 0.07, 0.07), Color(0.72, 0.30, 0.22))
	_box(Vector3(5.3, 1.78, 0.03), Vector3(0.62, 0.46, 0.02), Color(0.20, 0.38, 0.56))
	# A family photograph, deliberately too dark to read.
	_box(Vector3(4.82, 1.72, 2.9), Vector3(0.02, 0.40, 0.32), Color(0.22, 0.16, 0.11))
	_box(Vector3(4.835, 1.72, 2.9), Vector3(0.02, 0.30, 0.23), Color(0.10, 0.09, 0.08))
	_box(Vector3(6.9, 2.15, 0.03), Vector3(2.0, 0.34, 0.02), Color(0.42, 0.10, 0.13))
	var banner := Label3D.new()
	banner.text = "HAPPY BIRTHDAY"
	banner.font_size = 48
	banner.pixel_size = 0.005
	banner.modulate = Color(1.0, 0.86, 0.52)
	banner.shaded = false
	banner.position = Vector3(6.9, 2.15, 0.06)
	add_child(banner)

	# Bunting across the north wall.
	var flag_cols := [Color(0.70, 0.16, 0.18), Color(0.84, 0.64, 0.18),
		Color(0.20, 0.44, 0.68), Color(0.24, 0.54, 0.33), Color(0.52, 0.28, 0.58)]
	_box(Vector3(6.9, 2.32, 0.06), Vector3(3.6, 0.015, 0.015), Color(0.82, 0.80, 0.72))
	for i in range(10):
		var flag := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.18, 0.22, 0.02)
		flag.mesh = prism
		flag.position = Vector3(5.2 + i * 0.38, 2.22, 0.06)
		flag.rotation.z = PI
		flag.material_override = _mat(flag_cols[i % flag_cols.size()])
		add_child(flag)

	# Balloons.
	var balloons := [
		[Vector3(5.8, 1.55, 1.0), Color(0.68, 0.14, 0.18)],
		[Vector3(6.35, 1.72, 0.72), Color(0.82, 0.62, 0.16)],
		[Vector3(7.45, 1.62, 0.80), Color(0.18, 0.38, 0.66)],
		[Vector3(7.95, 1.42, 1.10), Color(0.22, 0.50, 0.30)],
		[Vector3(6.10, 1.80, 1.32), Color(0.50, 0.26, 0.56)],
	]
	for b in balloons:
		var bp: Vector3 = b[0]
		_sphere(bp, 0.14, b[1])
		var string := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.004
		cm.bottom_radius = 0.004
		cm.height = 0.70
		string.mesh = cm
		string.position = bp - Vector3(0, 0.45, 0)
		string.material_override = _mat(Color(0.80, 0.78, 0.70))
		add_child(string)

	# Candle flames. Cheap emissive spheres, no lights: eleven point lights
	# would be the most expensive thing in the game.
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.78, 0.32)
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.52, 0.13)
	flame_mat.emission_energy_multiplier = 2.4
	for i in range(11):
		var f := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.013
		sm.height = 0.028
		sm.radial_segments = 6
		sm.rings = 3
		f.mesh = sm
		var ang := TAU * i / 11.0
		f.position = Vector3(6.9 + cos(ang) * 0.11, 1.085, 1.6 + sin(ang) * 0.11)
		f.material_override = flame_mat
		add_child(f)

	# Sofa against the kitchen wall, facing the cake. The seat is the only
	# warm place to sit in the house, which is why it never gets used.
	_box(Vector3(6.9, 0.30, 3.72), Vector3(2.00, 0.40, 0.80), Color(0.16, 0.30, 0.29))
	_box(Vector3(6.9, 0.72, 4.04), Vector3(2.00, 0.56, 0.18), Color(0.16, 0.30, 0.29))
	_box(Vector3(5.95, 0.55, 3.72), Vector3(0.18, 0.62, 0.80), Color(0.19, 0.35, 0.33))
	_box(Vector3(7.85, 0.55, 3.72), Vector3(0.18, 0.62, 0.80), Color(0.19, 0.35, 0.33))
	_box(Vector3(6.52, 0.52, 3.66), Vector3(0.82, 0.14, 0.62), Color(0.24, 0.40, 0.38))
	_box(Vector3(7.28, 0.52, 3.66), Vector3(0.82, 0.14, 0.62), Color(0.24, 0.40, 0.38))
	_collider(Vector3(6.9, 0.38, 3.8), Vector3(2.00, 0.76, 0.80))
	_box(Vector3(5.55, 0.55, 3.58), Vector3(0.34, 0.34, 0.34), Color(0.58, 0.44, 0.20))

	# Coffee table in front of the sofa, with a mug and a book.
	_box(Vector3(6.9, 0.30, 2.95), Vector3(1.10, 0.06, 0.58), Color(0.36, 0.24, 0.16))
	for sx in [-0.46, 0.46]:
		for sz in [-0.22, 0.22]:
			_box(Vector3(6.9 + sx, 0.15, 2.95 + sz), Vector3(0.05, 0.30, 0.05),
				Color(0.30, 0.20, 0.13))
	_collider(Vector3(6.9, 0.15, 2.95), Vector3(1.10, 0.30, 0.58))
	_cyl(Vector3(6.70, 0.35, 2.92), 0.045, 0.04, 0.08, Color(0.76, 0.74, 0.68))
	_box(Vector3(7.10, 0.34, 2.98), Vector3(0.20, 0.025, 0.14), Color(0.22, 0.34, 0.50))

	# Rug.
	_box(Vector3(6.9, 0.010, 2.35), Vector3(2.7, 0.012, 1.9), Color(0.28, 0.14, 0.17))
	_box(Vector3(6.9, 0.013, 2.35), Vector3(2.4, 0.004, 1.6), Color(0.34, 0.19, 0.22))

	# Plant in the corner. One green thing makes the room feel lived in.
	_box(Vector3(8.45, 0.15, 3.80), Vector3(0.25, 0.30, 0.25), Color(0.40, 0.22, 0.14))
	_sphere(Vector3(8.45, 0.48, 3.80), 0.26, Color(0.16, 0.34, 0.19))
	_sphere(Vector3(8.55, 0.68, 3.72), 0.15, Color(0.18, 0.38, 0.21))

	# The birthday room's own light, so the warm pool has a source on screen.
	_ceiling_fixture(6.9, 1.9, 0.28, Color(1.0, 0.86, 0.60))


func _kitchen() -> void:
	_add_wall(Vector3((LIVE_X0 + TOTAL_X1) * 0.5, H * 0.5, TOTAL_Z1 + T * 0.5),
		Vector3(TOTAL_X1 - LIVE_X0, H, T), KITCH_COLOUR)
	_add_wall(Vector3(TOTAL_X1 + T * 0.5, H * 0.5, (LIVE_Z1 + TOTAL_Z1) * 0.5),
		Vector3(T, H, TOTAL_Z1 - LIVE_Z1), KITCH_COLOUR)
	# Close the kitchen's west side. Otherwise the kitchen opened into the
	# same sealed void the bedroom and hallway did.
	_add_wall(Vector3(LIVE_X0 - T * 0.5, H * 0.5, (LIVE_Z1 + TOTAL_Z1) * 0.5),
		Vector3(T, H, TOTAL_Z1 - LIVE_Z1), KITCH_COLOUR)

	# Lino. Cold rooms get cold floors.
	_box(Vector3(6.9, 0.008, 5.3), Vector3(4.08, 0.010, 2.08), Color(0.30, 0.36, 0.33))
	for i in range(8):
		var x := 5.05 + i * 0.50
		_box(Vector3(x, 0.012, 5.3), Vector3(0.012, 0.002, 2.08), Color(0.24, 0.30, 0.28))

	# Backsplash tiles.
	for i in range(10):
		var x := 5.1 + i * 0.36
		_box(Vector3(x, 1.12, TOTAL_Z1 - 0.075), Vector3(0.30, 0.30, 0.02),
			Color(0.44, 0.52, 0.46) if i % 2 == 0 else Color(0.38, 0.47, 0.41))

	# Counters along the south wall, with a sink under the window.
	_box(Vector3(7.0, 0.42, 6.08), Vector3(3.2, 0.84, 0.58), Color(0.34, 0.42, 0.37))
	_box(Vector3(7.0, 0.86, 6.08), Vector3(3.26, 0.05, 0.62), Color(0.62, 0.63, 0.57))
	_collider(Vector3(7.0, 0.44, 6.08), Vector3(3.2, 0.88, 0.58))
	# Cabinet doors and handles.
	for i in range(4):
		var x := 5.75 + i * 0.83
		_box(Vector3(x, 0.44, 5.78), Vector3(0.74, 0.70, 0.02), Color(0.29, 0.36, 0.32))
		_box(Vector3(x + 0.28, 0.62, 5.76), Vector3(0.10, 0.02, 0.02), Color(0.60, 0.58, 0.50))
	# Sink recess + tap.
	_box(Vector3(6.70, 0.865, 6.02), Vector3(0.56, 0.02, 0.38), Color(0.15, 0.18, 0.18))
	_cyl(Vector3(6.70, 0.96, 6.22), 0.018, 0.018, 0.18, Color(0.58, 0.60, 0.60))
	_box(Vector3(6.70, 1.04, 6.15), Vector3(0.02, 0.02, 0.16), Color(0.58, 0.60, 0.60))
	# Kettle, mugs, a dish rack. Signs of a tea that was never finished.
	_cyl(Vector3(5.80, 0.94, 6.02), 0.09, 0.11, 0.16, Color(0.70, 0.71, 0.68))
	_box(Vector3(5.80, 1.03, 6.13), Vector3(0.04, 0.04, 0.05), Color(0.30, 0.30, 0.30))
	_cyl(Vector3(7.55, 0.92, 6.00), 0.045, 0.04, 0.09, Color(0.80, 0.78, 0.70))
	_cyl(Vector3(7.46, 0.92, 5.92), 0.045, 0.04, 0.09, Color(0.72, 0.52, 0.50))
	_box(Vector3(8.05, 0.94, 5.98), Vector3(0.24, 0.10, 0.26), Color(0.55, 0.56, 0.54))

	# Upper cabinets.
	_box(Vector3(6.85, 1.98, 6.25), Vector3(2.4, 0.62, 0.24), Color(0.30, 0.38, 0.33))
	_box(Vector3(6.85, 1.66, 6.13), Vector3(2.4, 0.04, 0.02), Color(0.58, 0.56, 0.48))

	# Fridge. The only tall thing in the room, and the only thing humming.
	_box(Vector3(5.30, 0.90, 5.86), Vector3(0.72, 1.80, 0.70), Color(0.62, 0.65, 0.66))
	_box(Vector3(5.30, 1.02, 5.50), Vector3(0.68, 0.02, 0.02), Color(0.30, 0.32, 0.34))
	_box(Vector3(5.62, 1.15, 5.50), Vector3(0.03, 0.28, 0.03), Color(0.24, 0.26, 0.28))
	_collider(Vector3(5.30, 0.90, 5.86), Vector3(0.72, 1.80, 0.70))
	# Magnets + a child's drawing. The drawing is deliberately unreadable.
	_box(Vector3(5.30, 1.42, 5.495), Vector3(0.22, 0.26, 0.01), Color(0.86, 0.84, 0.76))
	_box(Vector3(5.30, 1.40, 5.49), Vector3(0.14, 0.14, 0.01), Color(0.24, 0.34, 0.58))
	for i in range(4):
		_box(Vector3(5.18 + i * 0.08, 1.58, 5.49), Vector3(0.03, 0.03, 0.02),
			[Color(0.72, 0.20, 0.20), Color(0.84, 0.68, 0.20),
			Color(0.20, 0.44, 0.66), Color(0.26, 0.56, 0.32)][i])

	# Kitchen window over the sink: the cold blue the whole room is lit by.
	_glow_box(Vector3(6.70, 1.55, TOTAL_Z1 - 0.045), Vector3(0.95, 0.70, 0.03),
		Color(0.30, 0.42, 0.64))
	_box(Vector3(6.70, 1.92, TOTAL_Z1 - 0.07), Vector3(1.10, 0.06, 0.06), TRIM)
	_box(Vector3(6.70, 1.18, TOTAL_Z1 - 0.07), Vector3(1.10, 0.06, 0.06), TRIM)
	_box(Vector3(6.15, 1.55, TOTAL_Z1 - 0.07), Vector3(0.06, 0.80, 0.06), TRIM)
	_box(Vector3(7.25, 1.55, TOTAL_Z1 - 0.07), Vector3(0.06, 0.80, 0.06), TRIM)
	_box(Vector3(6.70, 1.55, TOTAL_Z1 - 0.075), Vector3(0.035, 0.72, 0.04), TRIM)
	_box(Vector3(6.70, 1.55, TOTAL_Z1 - 0.075), Vector3(0.98, 0.035, 0.04), TRIM)
	# Curtains, thin and grey. Nobody opened them.
	_box(Vector3(6.00, 1.55, TOTAL_Z1 - 0.10), Vector3(0.20, 0.92, 0.03), Color(0.34, 0.36, 0.34))
	_box(Vector3(7.40, 1.55, TOTAL_Z1 - 0.10), Vector3(0.20, 0.92, 0.03), Color(0.34, 0.36, 0.34))


## A darker panel from floor to chair rail, plus the rail. Used in the hall
## and living room. Cheap boxes; kills the "unfinished greybox" read.
func _wainscot_x(z: float, x0: float, x1: float, room: Color) -> void:
	var w := x1 - x0
	if w <= 0.01:
		return
	var panel := DADO.lerp(room, 0.35)
	_box(Vector3((x0 + x1) * 0.5, 0.33, z), Vector3(w, 0.66, 0.02), panel)
	_box(Vector3((x0 + x1) * 0.5, 0.68, z), Vector3(w, 0.05, 0.035), DADO_LIGHT)
	# Vertical battens every ~0.45 m.
	var n := int(max(1.0, w / 0.45))
	for i in range(n + 1):
		var x := x0 + (w * i / float(n))
		_box(Vector3(x, 0.33, z + 0.012), Vector3(0.025, 0.66, 0.02), DADO_LIGHT)


func _wainscot_z(x: float, z0: float, z1: float, room: Color) -> void:
	var d := z1 - z0
	if d <= 0.01:
		return
	var panel := DADO.lerp(room, 0.35)
	_box(Vector3(x, 0.33, (z0 + z1) * 0.5), Vector3(0.02, 0.66, d), panel)
	_box(Vector3(x, 0.68, (z0 + z1) * 0.5), Vector3(0.035, 0.05, d), DADO_LIGHT)
	var n := int(max(1.0, d / 0.45))
	for i in range(n + 1):
		var z := z0 + (d * i / float(n))
		_box(Vector3(x + 0.012, 0.33, z), Vector3(0.02, 0.66, 0.025), DADO_LIGHT)


## Skirting boards. Split at every doorway so they do not run through a gap.
func _skirting() -> void:
	# Bedroom.
	_skirt_x(0.075, 0.075, BED_X1 - 0.075)
	_skirt_x(BED_Z1 - 0.075, 0.075, BED_X1 - 0.075)
	_skirt_z(0.075, 0.075, BED_Z1 - 0.075)
	_skirt_z(BED_X1 - 0.135, 0.075, 1.23)
	_skirt_z(BED_X1 - 0.135, 2.17, BED_Z1 - 0.075)
	# Hallway.
	_skirt_x(0.075, HALL_X0 + 0.075, HALL_X1 - 0.075)
	_skirt_z(HALL_X0 + 0.075, 0.075, 1.23)
	_skirt_z(HALL_X0 + 0.075, 2.17, HALL_Z1 - 0.075)
	_skirt_z(HALL_X1 - 0.075, 0.075, 1.63)
	_skirt_z(HALL_X1 - 0.075, 2.57, HALL_Z1 - 0.075)
	# Living.
	_skirt_x(0.075, LIVE_X0 + 0.075, TOTAL_X1 - 0.075)
	_skirt_z(LIVE_X0 + 0.075, 0.075, 1.63)
	_skirt_z(LIVE_X0 + 0.075, 2.57, LIVE_Z1 - 0.075)
	_skirt_z(TOTAL_X1 - 0.075, 0.075, LIVE_Z1 - 0.075)
	_skirt_x(LIVE_Z1 - 0.075, LIVE_X0 + 0.075, 7.62)
	_skirt_x(LIVE_Z1 - 0.075, 8.58, TOTAL_X1 - 0.075)
	# Kitchen.
	_skirt_x(TOTAL_Z1 - 0.075, LIVE_X0 + 0.075, TOTAL_X1 - 0.075)
	_skirt_z(LIVE_X0 + 0.075, LIVE_Z1 + 0.075, TOTAL_Z1 - 0.075)
	_skirt_z(TOTAL_X1 - 0.075, LIVE_Z1 + 0.075, TOTAL_Z1 - 0.075)
	_skirt_x(LIVE_Z1 + 0.075, LIVE_X0 + 0.075, 7.62)
	_skirt_x(LIVE_Z1 + 0.075, 8.58, TOTAL_X1 - 0.075)


func _skirt_x(z: float, x0: float, x1: float) -> void:
	var w := x1 - x0
	if w <= 0.01:
		return
	_box(Vector3((x0 + x1) * 0.5, 0.055, z), Vector3(w, 0.11, 0.028), TRIM)


func _skirt_z(x: float, z0: float, z1: float) -> void:
	var d := z1 - z0
	if d <= 0.01:
		return
	_box(Vector3(x, 0.055, (z0 + z1) * 0.5), Vector3(0.028, 0.11, d), TRIM)


## Frames around the four doorways. One side only, but it is the side seen
## from the room the player is in, and it makes the shell read as built.
func _door_trim_all() -> void:
	_door_trim(Vector3(BED_X1 - 0.14, 0.0, 1.7), true)
	_door_trim(Vector3(LIVE_X0 + 0.02, 0.0, 2.1), true)
	_door_trim(Vector3(8.1, 0.0, LIVE_Z1 - 0.08), false)
	_door_trim(Vector3(4.2, 0.0, HALL_Z1 - 0.05), false)


func _door_trim(center: Vector3, along_z: bool) -> void:
	var col := TRIM
	if along_z:
		_box(Vector3(center.x, DOOR_H * 0.5, center.z - DOOR_W * 0.5 - 0.025),
			Vector3(0.07, DOOR_H, 0.09), col)
		_box(Vector3(center.x, DOOR_H * 0.5, center.z + DOOR_W * 0.5 + 0.025),
			Vector3(0.07, DOOR_H, 0.09), col)
		_box(Vector3(center.x, DOOR_H + 0.04, center.z),
			Vector3(0.07, 0.08, DOOR_W + 0.14), col)
	else:
		_box(Vector3(center.x - DOOR_W * 0.5 - 0.025, DOOR_H * 0.5, center.z),
			Vector3(0.09, DOOR_H, 0.07), col)
		_box(Vector3(center.x + DOOR_W * 0.5 + 0.025, DOOR_H * 0.5, center.z),
			Vector3(0.09, DOOR_H, 0.07), col)
		_box(Vector3(center.x, DOOR_H + 0.04, center.z),
			Vector3(DOOR_W + 0.14, 0.08, 0.07), col)


# ---------------------------------------------------------------- decoration

func _decor() -> void:
	# --- bedroom window ---------------------------------------------------
	# Cold blue glass. This is the only light source the story allows to be
	# constant, so it is also the most saturated surface in the house.
	_glow_box(Vector3(1.25, 1.52, 0.045), Vector3(0.98, 0.92, 0.03),
		Color(0.48, 0.64, 0.98))
	for i in range(4):
		var x := 0.86 + i * 0.26
		_box(Vector3(x, 1.52, 0.032), Vector3(0.012, 0.90, 0.01),
			Color(0.20, 0.26, 0.36))
	_box(Vector3(1.25, 1.02, 0.05), Vector3(1.10, 0.06, 0.07), TRIM)
	_box(Vector3(1.25, 2.02, 0.05), Vector3(1.10, 0.06, 0.07), TRIM)
	_box(Vector3(0.72, 1.52, 0.05), Vector3(0.06, 1.06, 0.07), TRIM)
	_box(Vector3(1.78, 1.52, 0.05), Vector3(0.06, 1.06, 0.07), TRIM)
	_box(Vector3(1.25, 1.52, 0.055), Vector3(0.035, 0.94, 0.05), TRIM)
	_box(Vector3(1.25, 1.52, 0.055), Vector3(1.02, 0.035, 0.05), TRIM)
	# Sill, deep enough to catch the light.
	_box(Vector3(1.25, 0.98, 0.11), Vector3(1.24, 0.05, 0.18), TRIM)
	# Curtains and a rod. The blue glass alone read like a hole in the wall.
	_box(Vector3(1.25, 2.10, 0.10), Vector3(1.52, 0.035, 0.035), Color(0.24, 0.19, 0.15))
	_box(Vector3(0.56, 1.55, 0.10), Vector3(0.28, 1.10, 0.045), Color(0.36, 0.12, 0.15))
	_box(Vector3(1.94, 1.55, 0.10), Vector3(0.28, 1.10, 0.045), Color(0.36, 0.12, 0.15))
	_box(Vector3(0.56, 1.10, 0.125), Vector3(0.28, 0.02, 0.05), Color(0.44, 0.16, 0.18))
	_box(Vector3(1.94, 1.10, 0.125), Vector3(0.28, 0.02, 0.05), Color(0.44, 0.16, 0.18))

	# Rug, poster, bedside lamp, toy.
	_box(Vector3(2.10, 0.012, 1.90), Vector3(1.45, 0.02, 1.15), Color(0.34, 0.14, 0.18))
	_box(Vector3(2.10, 0.018, 1.90), Vector3(1.20, 0.006, 0.92), Color(0.40, 0.18, 0.22))
	# A poster on the bedroom wall: dark sky, one pale shape. Not a real
	# image, but enough that the wall is not a flat rectangle.
	_box(Vector3(3.465, 1.72, 2.20), Vector3(0.02, 0.58, 0.44), Color(0.62, 0.34, 0.20))
	_box(Vector3(3.455, 1.72, 2.20), Vector3(0.02, 0.44, 0.32), Color(0.18, 0.24, 0.36))
	_box(Vector3(3.445, 1.82, 2.20), Vector3(0.01, 0.14, 0.16), Color(0.74, 0.72, 0.62))
	_box(Vector3(3.445, 1.60, 2.20), Vector3(0.01, 0.06, 0.24), Color(0.48, 0.16, 0.16))

	# Bedside lamp: a warm island in a blue room. Moved to the far corner of
	# the nightstand so it does not sit directly behind the clock face.
	_cyl(Vector3(1.68, 0.60, 3.05), 0.05, 0.06, 0.04, Color(0.28, 0.22, 0.16))
	_cyl(Vector3(1.68, 0.66, 3.05), 0.08, 0.11, 0.11, Color(0.78, 0.64, 0.42),
		0.0, null, true)
	_cyl(Vector3(1.68, 0.72, 3.05), 0.030, 0.030, 0.02, Color(0.94, 0.84, 0.60),
		0.0, null, true)

	# The clock gets a body, a face and a tiny red standby dot. It faces the
	# room (-Z), which is where the child sits up and looks from.
	_box(Vector3(1.85, 0.635, 2.86), Vector3(0.34, 0.17, 0.13), Color(0.08, 0.08, 0.09))
	_box(Vector3(1.85, 0.585, 2.86), Vector3(0.38, 0.02, 0.17), Color(0.12, 0.12, 0.13))
	_box(Vector3(1.85, 0.635, 2.792), Vector3(0.28, 0.12, 0.005), Color(0.03, 0.05, 0.07))
	_box(Vector3(1.70, 0.585, 2.792), Vector3(0.014, 0.014, 0.005), Color(0.90, 0.14, 0.10))

	# Books on the floor and a school bag by the bed: signs someone lives here.
	_box(Vector3(0.45, 0.028, 1.05), Vector3(0.30, 0.05, 0.21), Color(0.52, 0.14, 0.16))
	_box(Vector3(0.48, 0.070, 1.03), Vector3(0.27, 0.04, 0.19), Color(0.16, 0.30, 0.52))
	_box(Vector3(0.43, 0.105, 1.07), Vector3(0.24, 0.03, 0.17), Color(0.22, 0.42, 0.28))
	_box(Vector3(1.45, 0.15, 3.02), Vector3(0.30, 0.28, 0.20), Color(0.14, 0.20, 0.32))
	_box(Vector3(1.45, 0.24, 3.12), Vector3(0.07, 0.22, 0.035), Color(0.09, 0.13, 0.22))
	_box(Vector3(2.55, 0.055, 3.05), Vector3(0.20, 0.11, 0.15), Color(0.58, 0.18, 0.20))
	_box(Vector3(2.55, 0.12, 3.05), Vector3(0.16, 0.03, 0.11), Color(0.72, 0.56, 0.22))
	# Slippers.
	_box(Vector3(1.15, 0.04, 1.12), Vector3(0.12, 0.06, 0.22), Color(0.32, 0.22, 0.18))
	_box(Vector3(1.34, 0.04, 1.16), Vector3(0.12, 0.06, 0.22), Color(0.32, 0.22, 0.18))

	# Ceiling fixture above the bed (the warm omni is the actual light).
	_ceiling_fixture(1.85, 1.4, 0.20, Color(0.92, 0.80, 0.58))

	# The streetlight on the ceiling. The window spot lights the floor; this
	# one points up at the plaster, so the first shot of the game has the
	# blue pool the opening line is about.
	var ceil_spot := SpotLight3D.new()
	ceil_spot.name = "CeilingStreetlight"
	ceil_spot.position = Vector3(1.25, 1.05, 0.35)
	ceil_spot.rotation_degrees = Vector3(132.0, 0.0, 0.0)
	ceil_spot.light_color = Color(0.44, 0.60, 1.0)
	ceil_spot.light_energy = 3.40
	ceil_spot.spot_range = 4.0
	ceil_spot.spot_angle = 46.0
	ceil_spot.spot_attenuation = 0.9
	ceil_spot.shadow_enabled = false
	add_child(ceil_spot)

	# A ceiling is a big empty surface in the wake shot. One attic hatch,
	# two cracked seams and a water stain give it something to be. The
	# ceiling plane's underside is H - 0.05, not H: everything here sits
	# just below that or it is buried inside the slab.
	var hatch := Color(0.46, 0.44, 0.40)
	_box(Vector3(2.40, H - 0.055, 1.15), Vector3(0.64, 0.010, 0.64), hatch)
	_box(Vector3(2.40, H - 0.060, 1.15), Vector3(0.56, 0.008, 0.56),
		Color(0.40, 0.38, 0.35))
	_box(Vector3(2.40, H - 0.064, 1.15), Vector3(0.62, 0.006, 0.02),
		Color(0.22, 0.20, 0.18))
	_box(Vector3(2.40, H - 0.064, 1.15), Vector3(0.02, 0.006, 0.62),
		Color(0.22, 0.20, 0.18))
	var crack := Color(0.19, 0.18, 0.17)
	_box(Vector3(0.55, H - 0.058, 1.55), Vector3(0.010, 0.006, 0.85), crack, 0.38)
	_box(Vector3(0.88, H - 0.058, 2.48), Vector3(0.010, 0.006, 0.55), crack, -0.62)
	_box(Vector3(2.95, H - 0.058, 2.25), Vector3(0.010, 0.006, 0.42), crack, 1.05)
	_cyl(Vector3(0.42, H - 0.059, 2.95), 0.17, 0.17, 0.004, Color(0.24, 0.22, 0.19))

	# --- hallway ----------------------------------------------------------
	_box(Vector3(4.2, 0.012, 2.30), Vector3(0.62, 0.02, 2.20), Color(0.34, 0.16, 0.14))
	_box(Vector3(4.2, 0.018, 2.30), Vector3(0.46, 0.006, 1.95), Color(0.42, 0.21, 0.17))

	# Four photographs on the east wall. Faces are a dark blur on purpose.
	for i in range(4):
		var z := 0.85 + i * 0.72
		_box(Vector3(4.66, 1.58, z), Vector3(0.03, 0.30, 0.24), Color(0.20, 0.14, 0.10))
		_box(Vector3(4.645, 1.58, z), Vector3(0.02, 0.22, 0.17),
			Color(0.34, 0.32, 0.29) if i % 2 == 0 else Color(0.30, 0.33, 0.31))
		_box(Vector3(4.635, 1.60, z), Vector3(0.01, 0.09, 0.09), Color(0.08, 0.07, 0.07))

	# Console table and telephone by Mum's door. She was waiting up.
	_box(Vector3(4.62, 0.40, 3.90), Vector3(0.26, 0.04, 0.62), Color(0.34, 0.23, 0.16))
	for sx in [-0.08, 0.08]:
		for sz in [-0.25, 0.25]:
			_box(Vector3(4.62 + sx, 0.19, 3.90 + sz), Vector3(0.04, 0.38, 0.04),
				Color(0.28, 0.18, 0.12))
	_box(Vector3(4.62, 0.47, 3.86), Vector3(0.13, 0.09, 0.16), Color(0.10, 0.10, 0.12))
	_box(Vector3(4.62, 0.53, 3.93), Vector3(0.17, 0.035, 0.06), Color(0.10, 0.10, 0.12))
	_box(Vector3(4.62, 0.455, 3.60), Vector3(0.20, 0.01, 0.14), Color(0.70, 0.68, 0.62))
	_box(Vector3(4.62, 0.465, 3.60), Vector3(0.16, 0.008, 0.11), Color(0.80, 0.78, 0.72))

	# Coat rack. Three dark coats. At the end of a hallway, a coat is a person
	# until you look at it, and sometimes after. Costs ten boxes.
	_cyl(Vector3(4.66, 0.95, 0.42), 0.02, 0.025, 1.90, Color(0.26, 0.18, 0.12))
	_box(Vector3(4.66, 1.02, 0.40), Vector3(0.30, 0.66, 0.16), Color(0.14, 0.13, 0.15))
	_box(Vector3(4.64, 1.10, 0.52), Vector3(0.24, 0.52, 0.12), Color(0.18, 0.14, 0.13))
	_box(Vector3(4.62, 1.18, 0.31), Vector3(0.20, 0.44, 0.10), Color(0.12, 0.12, 0.14))

	_ceiling_fixture(4.2, 2.35, 0.16, Color(0.92, 0.80, 0.58))

	# --- kitchen cold spot -------------------------------------------------
	# A small amount of clutter on the counter so the room is not a set.
	_box(Vector3(8.30, 0.90, 6.02), Vector3(0.22, 0.03, 0.16), Color(0.68, 0.66, 0.60))
	_box(Vector3(8.30, 0.94, 6.02), Vector3(0.16, 0.06, 0.12), Color(0.52, 0.20, 0.18))
	_ceiling_fixture(6.9, 5.35, 0.22, Color(0.72, 0.82, 0.78), true)


# ---------------------------------------------------------------- primitives

func _box(pos: Vector3, size: Vector3, col: Color, rot_y := 0.0,
		parent: Node3D = null, rough := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation.y = rot_y
	mi.material_override = _mat(col, rough)
	if parent == null:
		add_child(mi)
	else:
		parent.add_child(mi)
	return mi


func _glow_box(pos: Vector3, size: Vector3, col: Color) -> MeshInstance3D:
	var mi := _box(pos, size, col)
	var m := _mat(col)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.65
	mi.material_override = m
	return mi


func _cyl(pos: Vector3, top_r: float, bottom_r: float, height: float,
		col: Color, rot_x := 0.0, parent: Node3D = null,
		glow := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bottom_r
	cm.height = height
	cm.radial_segments = 12
	mi.mesh = cm
	mi.position = pos
	mi.rotation.x = rot_x
	if glow:
		var gm := _mat(col)
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.emission_enabled = true
		gm.emission = col
		gm.emission_energy_multiplier = 0.9
		mi.material_override = gm
	else:
		mi.material_override = _mat(col)
	if parent == null:
		add_child(mi)
	else:
		parent.add_child(mi)
	return mi


func _sphere(pos: Vector3, radius: float, col: Color,
		parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.position = pos
	mi.material_override = _mat(col)
	if parent == null:
		add_child(mi)
	else:
		parent.add_child(mi)
	return mi


func _glow_sphere(pos: Vector3, radius: float, col: Color,
		parent: Node3D = null) -> MeshInstance3D:
	var mi := _sphere(pos, radius, col, parent)
	var m := _mat(col)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 1.2
	mi.material_override = m
	return mi


func _collider(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _omni(pos: Vector3, col: Color, energy: float, reach: float,
		shadow := false) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = col
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.35
	light.shadow_enabled = shadow
	light.set_meta("base_energy", energy)
	add_child(light)
	return light


func _ceiling_fixture(x: float, z: float, radius: float, col: Color,
		cold := false) -> void:
	# Ceiling rose.
	_cyl(Vector3(x, H - 0.060, z), radius * 0.55, radius * 0.55, 0.03,
		Color(0.50, 0.48, 0.44))
	# Chain.
	_cyl(Vector3(x, H - 0.10, z), 0.012, 0.012, 0.16, Color(0.30, 0.30, 0.30))
	# Shade: a shallow cone, wider at the bottom, glowing underneath.
	_cyl(Vector3(x, H - 0.21, z), radius * 0.45, radius, 0.16, col, 0.0, null, true)
	# Bulb.
	_glow_sphere(Vector3(x, H - 0.28, z), radius * 0.24,
		Color(0.94, 0.90, 0.78) if not cold else Color(0.78, 0.90, 0.88))


func _mat(c: Color, rough := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


# ---------------------------------------------------------------- lighting

## Ambient + one cold window light + one warm practical per room. The only
## shadow map in the game belongs to the player's flashlight (player.gd).
func _lights() -> void:
	var amb := WorldEnvironment.new()
	amb.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006, 0.007, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.15, 0.17, 0.24)
	env.ambient_light_energy = 0.26
	# Depth fog. It is the cheapest way to make the far end of a hallway stop
	# existing, and it hides the seams of a code-built shell.
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.025, 0.045)
	env.fog_light_energy = 0.30
	env.fog_density = 0.030
	env.fog_height = 1.1
	env.fog_height_density = 0.10
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.02
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.16
	env.adjustment_saturation = 1.15
	amb.environment = env
	add_child(amb)

	# The streetlight. Cold blue, moving very slightly, as if a car is passing.
	var sun := DirectionalLight3D.new()
	sun.name = "Streetlight"
	sun.light_color = Color(0.52, 0.62, 0.88)
	sun.light_energy = 0.22
	sun.shadow_enabled = false   # the flashlight owns the only shadow map
	sun.rotation_degrees = Vector3(-38.0, 145.0, 0.0)
	sun.position = Vector3(4.0, 4.0, 1.0)
	add_child(sun)

	# The visible pool: a cool spot through the bedroom window. This is what
	# the child is actually looking at when they say the streetlight is
	# moving across the ceiling.
	_street_spot = SpotLight3D.new()
	_street_spot.name = "WindowLight"
	_street_spot.position = Vector3(1.25, 1.92, 0.10)
	_street_spot.rotation_degrees = Vector3(-132.0, 0.0, 0.0)
	_street_spot.light_color = Color(0.44, 0.58, 0.92)
	_street_spot.light_energy = 2.45
	_street_spot.spot_range = 7.5
	_street_spot.spot_angle = 58.0
	_street_spot.spot_attenuation = 1.0
	_street_spot.shadow_enabled = false
	add_child(_street_spot)

	# Practicals. These are what make the rooms readable without the torch
	# and what the old grey box was missing.
	_lamp_omni = _omni(Vector3(1.85, 0.76, 2.95), Color(1.0, 0.70, 0.38), 0.62, 2.6)
	_hall_omni = _omni(Vector3(4.2, 2.28, 2.10), Color(1.0, 0.78, 0.46), 0.62, 3.2)
	_hall_far = _omni(Vector3(4.2, 1.90, 4.20), Color(1.0, 0.66, 0.36), 0.26, 2.0)
	_living_omni = _omni(Vector3(6.9, 2.26, 1.95), Color(1.0, 0.76, 0.46), 1.20, 5.6)
	_floor_lamp = _omni(Vector3(5.20, 1.10, 3.78), Color(1.0, 0.68, 0.38), 0.52, 2.8)
	_fluor = _omni(Vector3(6.9, 2.22, 5.35), Color(0.70, 0.86, 0.80), 0.55, 4.0)
	_leak_omni = _omni(Vector3(4.2, 0.16, 4.50), Color(1.0, 0.66, 0.32), 0.22, 1.2)

	# Cake candles, as one warm point light. Eleven would be absurd.
	_omni(Vector3(6.9, 1.12, 1.6), Color(1.0, 0.62, 0.26), 0.40, 1.7)
