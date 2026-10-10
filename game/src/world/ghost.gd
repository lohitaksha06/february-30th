extends CharacterBody3D
class_name Ghost
## A lost soul. Patrols its ground, hears noise, sees movement, chases.
##
## No health, no attack animation, no weapon on either side. The whole chase
## is: vision cone + hearing radius + your stamina bar. docs/worlds.md.
## ~10 boxes, unshaded where it counts, zero shadow maps. Same 800-tri
## spirit as Wren, amplitude turned up: stretched limbs, no eyes.

enum G { PATROL, SUSPICIOUS, CHASE, SEARCH }

const PATROL_SPEED := 1.2
const CHASE_SPEED := 3.6      # slower than your sprint (4.2), faster than walk
const SEARCH_SPEED := 1.6
const VIEW_DIST := 14.0
const VIEW_COS := 0.82        # ~35-degree half cone
const CATCH_DIST := 1.35
const LOSE_TIME := 5.0
const GRAVITY := 9.8

var state: int = G.PATROL
var patrol_points: Array[Vector3] = []
var spawn_pos := Vector3.ZERO
var player: Node3D = null
var director: Node = null      # act1, for caught_by() + hiding checks
var active := false
var grace := false             # spawn protection: blind and harmless

var _wp_idx := 0
var _sense_accum := 0.0
var _susp_t := 0.0
var _lose_t := 0.0
var _search_t := 0.0
var _last_seen := Vector3.ZERO
var _suspect := Vector3.ZERO
var _dest := Vector3.ZERO
var _has_dest := false
var _t := 0.0
var _body: MeshInstance3D
var _head: MeshInstance3D


func _ready() -> void:
	_build()
	spawn_pos = global_position


func setup(p: Node3D, d: Node, points: Array[Vector3]) -> void:
	player = p
	director = d
	patrol_points = points
	_wp_idx = 0
	state = G.PATROL
	_has_dest = false
	active = true


func reset() -> void:
	global_position = spawn_pos
	velocity = Vector3.ZERO
	state = G.PATROL
	_has_dest = false
	_lose_t = 0.0
	_search_t = 0.0
	_susp_t = 0.0


func is_chasing() -> bool:
	return active and state == G.CHASE


func _build() -> void:
	var dark := _mat(Color(0.07, 0.07, 0.10))
	var pale := _mat(Color(0.84, 0.82, 0.78))
	pale.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # face reads in the dark

	# Tall thin body, stretched past charm. docs/art-direction.md §4.1b.
	_body = _box(Vector3(0.36, 1.30, 0.28), Vector3(0, 0.95, 0), dark)
	# Head + squeezed pale face. NO eyes drawn -- worse without them.
	_head = _box(Vector3(0.30, 0.36, 0.26), Vector3(0, 1.78, 0), dark)
	var face := _box(Vector3(0.24, 0.20, 0.02), Vector3(0, -0.02, 0.13), pale, _head)
	face.scale = Vector3(1.0, 0.6, 1.0)
	_head.rotation_degrees = Vector3(6, 0, 9)  # held wrong tilt
	# Arms: one normal, one dragging on the ground
	_box(Vector3(0.09, 0.55, 0.09), Vector3(-0.24, 0.85, 0), dark)
	_box(Vector3(0.09, 1.05, 0.09), Vector3(0.25, 0.55, 0.02), dark)

	var blob := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
	blob.mesh = q
	blob.rotation_degrees = Vector3(-90, 0, 0)
	blob.position = Vector3(0, 0.02, 0)
	blob.material_override = _mat(Color(0, 0, 0, 0.5), true)
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


func _physics_process(delta: float) -> void:
	_t += delta
	if _body != null:
		# hover-bob: it doesn't walk, it drifts. Cheaper than leg animation.
		_body.position.y = 0.95 + sin(_t * 1.3 + float(get_instance_id() % 10)) * 0.05

	if not active:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1

	_sense_accum += delta
	if _sense_accum >= 0.1:
		_sense_accum = 0.0
		_think(0.1)

	var speed := PATROL_SPEED
	match state:
		G.CHASE:
			speed = CHASE_SPEED
			# Hidden means unseen AND untracked: it goes to where it last
			# saw you, not where you are. Break sightlines, then go small.
			if _player_hidden():
				_dest = _last_seen
			else:
				_dest = (player.global_position if player != null else _last_seen)
			_has_dest = player != null
		G.SEARCH:
			speed = SEARCH_SPEED
		G.SUSPICIOUS:
			speed = 0.0
			_dest = _suspect
			_has_dest = true
		G.PATROL:
			speed = PATROL_SPEED
			if not _has_dest and not patrol_points.is_empty():
				_dest = patrol_points[_wp_idx]
				_has_dest = true

	if _has_dest and state != G.SUSPICIOUS:
		var to: Vector3 = _dest - global_position
		to.y = 0.0
		if to.length() < 0.5:
			_has_dest = false
			if state == G.PATROL and not patrol_points.is_empty():
				_wp_idx = (_wp_idx + 1) % patrol_points.size()
		else:
			var d: Vector3 = to.normalized()
			velocity.x = d.x * speed
			velocity.z = d.z * speed
			rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), minf(1.0, delta * 4.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 20.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 20.0)
		if state == G.SUSPICIOUS and _has_dest:
			var to2: Vector3 = _dest - global_position
			if to2.length() > 0.1:
				rotation.y = lerp_angle(rotation.y, atan2(-to2.x, -to2.z), minf(1.0, delta * 5.0))

	move_and_slide()


## Senses tick at 10 Hz. A ghost does not need 60 samples a second.
func _think(tick: float) -> void:
	if player == null or grace:
		return
	var seen := _can_see()
	match state:
		G.PATROL:
			if seen:
				_begin_chase()
			elif _hears() > 0.0:
				state = G.SUSPICIOUS
				_suspect = player.global_position
				_susp_t = 0.0
		G.SUSPICIOUS:
			_susp_t += tick
			if seen:
				_begin_chase()
			elif _susp_t > 2.5:
				state = G.PATROL
				_has_dest = false
		G.CHASE:
			if seen:
				_last_seen = player.global_position
				_lose_t = 0.0
			else:
				_lose_t += tick
			var pd: float = global_position.distance_to(player.global_position)
			if pd < CATCH_DIST:
				if director != null and director.has_method("caught_by"):
					director.caught_by(self)
				return
			if _lose_t >= LOSE_TIME:
				state = G.SEARCH
				_search_t = 0.0
				_dest = _last_seen + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))
				_has_dest = true
		G.SEARCH:
			_search_t += tick
			if seen:
				_begin_chase()
			elif _search_t > 6.0:
				state = G.PATROL
				_has_dest = false
			elif not _has_dest:
				_dest = _last_seen + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
				_has_dest = true


func _begin_chase() -> void:
	state = G.CHASE
	_lose_t = 0.0
	if player != null:
		_last_seen = player.global_position


func _player_hidden() -> bool:
	if director != null and director.has_method("is_player_hidden"):
		return bool(director.call("is_player_hidden"))
	return false


## Hearing: your noise radius vs distance. Running is what gets you caught.
func _hears() -> float:
	if player == null:
		return 0.0
	var r := 2.0
	if player.has_method("current_noise_radius"):
		r = float(player.call("current_noise_radius"))
	var pd: float = global_position.distance_to(player.global_position)
	return r if r >= pd else 0.0


func _can_see() -> bool:
	if player == null or grace:
		return false
	# Crouched inside a hollow rock: invisible. This is the hide verb.
	if _player_hidden():
		return false
	var eye := global_position + Vector3(0, 1.7, 0)
	var target: Vector3 = player.global_position + Vector3(0, 1.1, 0)
	var to: Vector3 = target - eye
	var dist := to.length()
	if dist > VIEW_DIST:
		return false
	if dist > 0.5:
		var fwd := -global_transform.basis.z
		fwd.y = 0.0
		var flat := to
		flat.y = 0.0
		if flat.length() > 0.01 and fwd.dot(flat.normalized()) < VIEW_COS:
			# Too close to ignore: within 2.5 m it feels you regardless.
			if dist > 2.5:
				return false
	# Line of sight: walls and rocks block it. Hide zones work because
	# the rock is genuinely between you.
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(eye, target)
	var excl: Array[RID] = [get_rid()]
	if player is CollisionObject3D:
		excl.append((player as CollisionObject3D).get_rid())
	params.exclude = excl
	var hit: Dictionary = space.intersect_ray(params)
	return hit.is_empty()
