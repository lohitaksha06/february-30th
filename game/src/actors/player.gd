extends CharacterBody3D
class_name Player
## First-person controller. Crouch / walk / sprint, flashlight, and the noise
## this whole game is actually about.
##
## There is no combat, no weapon, and no attack. Ever. The verbs are run, hide,
## and be kind. docs/story.md tone rule 3.
##
## There is also no stamina bar in the prologue. Sprint is limited by
## geometry -- alleys are short and safe, open rooms are long and lethal.
## docs/worlds.md.
##
## Act 1 (the cavern) deliberately deviates: the player asked for a limited
## stamina bar there, so sprint drains `stamina` while `stamina_enabled`.
## Prologue leaves it off and plays exactly as before.

signal noise_emitted(radius: float)
signal crossed_midnight

const EYE_STAND := 1.62
const EYE_CROUCH := 0.95
const MOUSE_SENS := 0.0022
## Look sensitivity while crouched drops 40%. docs/tech-stack.md §8.3 rule 3.
const CROUCH_SENS_MULT := 0.6
const WALK_SPEED := 1.8
const CROUCH_SPEED := 0.6
const SPRINT_SPEED := 4.2
const GRAVITY := 9.8
const JUMP_VELOCITY := 4.2

var can_move := true

## Act 1 stamina. Off unless the director enables it.
var stamina_enabled := false
var stamina := 1.0            ## 0..1, drains on sprint, regens otherwise
var exhausted := false
const STAMINA_DRAIN := 0.28   ## ~3.5 s of sprint from full
const STAMINA_REGEN := 0.18
const EXHAUST_CLEAR := 0.35   ## must recover this far before sprint returns

@onready var head: Node3D = $Head
@onready var cam: Camera3D = $Head/Camera3D
@onready var flash: SpotLight3D = $Head/Camera3D/Flashlight

var _pitch := 0.0
var _crouch_t := 0.0      ## 0 = standing, 1 = fully crouched. Smoothed.
var _vel_y := 0.0
var _noise_accum := 0.0


func _ready() -> void:
	cam.fov = 70.0
	cam.near = 0.05
	cam.far = 40.0
	flash.spot_range = 11.0
	flash.spot_angle = 26.0
	flash.spot_attenuation = 1.4
	flash.light_energy = 2.6
	flash.shadow_enabled = false      # no shadow maps, ever. docs/art-direction.md §7
	flash.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := MOUSE_SENS
		if _crouch_t > 0.5:
			sens *= CROUCH_SENS_MULT
		rotate_y(-event.relative.x * sens)
		_pitch = clampf(_pitch - event.relative.y * sens, -1.45, 1.45)
		head.rotation.x = _pitch

	# Touch look: drag anywhere on the right half of the screen.
	elif event is InputEventScreenDrag:
		var half := get_viewport().get_visible_rect().size.x * 0.5
		if event.position.x > half:
			var sens := MOUSE_SENS * 1.6
			if _crouch_t > 0.5:
				sens *= CROUCH_SENS_MULT
			rotate_y(-event.relative.x * sens)
			_pitch = clampf(_pitch - event.relative.y * sens, -1.45, 1.45)
			head.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		_vel_y -= GRAVITY * delta
	if is_on_floor() and _vel_y < 0.0:
		_vel_y = -0.1

	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	var state := InputSetup.current_state()

	# Smooth the crouch. Snapping between eye heights is nauseating and this
	# is a 45 minute game played in the dark.
	var target := 1.0 if state == InputSetup.MoveState.CROUCH else 0.0
	_crouch_t = move_toward(_crouch_t, target, delta * 6.0)
	head.position.y = lerpf(EYE_STAND, EYE_CROUCH, _crouch_t)
	# Duck under a low wardrobe? No collision change needed -- the wardrobe
	# door is handled by the cutscene. Keep it simple.

	var speed := WALK_SPEED
	match state:
		InputSetup.MoveState.CROUCH:
			speed = CROUCH_SPEED
		InputSetup.MoveState.SPRINT:
			speed = SPRINT_SPEED

	# Act 1 stamina: sprinting on an empty bar drops you to a walk.
	# Prologue never enables this and is unaffected.
	if stamina_enabled:
		var sprinting := state == InputSetup.MoveState.SPRINT and input_dir.length() > 0.1 and can_move
		if sprinting and not exhausted:
			stamina = maxf(0.0, stamina - STAMINA_DRAIN * delta)
			if stamina <= 0.0:
				exhausted = true
		elif not sprinting:
			stamina = minf(1.0, stamina + STAMINA_REGEN * delta)
			if exhausted and stamina >= EXHAUST_CLEAR:
				exhausted = false
		if exhausted and state == InputSetup.MoveState.SPRINT:
			speed = WALK_SPEED

	var dir := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y))
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()

	if not can_move:
		dir = Vector3.ZERO
		speed = 0.0

	var target_vel := dir * speed
	velocity.x = lerpf(velocity.x, target_vel.x, delta * 12.0)
	velocity.z = lerpf(velocity.z, target_vel.z, delta * 12.0)
	velocity.y = _vel_y
	move_and_slide()

	# Bob, subtle. At 30fps through a VHS filter this sells footsteps for free
	# and costs nothing -- no footstep animation exists in this project.
	var hv := Vector3.ZERO
	if dir.length() > 0.05 and is_on_floor():
		var amp := 0.028 if state == InputSetup.MoveState.WALK else 0.05
		var hz := 9.0 if state == InputSetup.MoveState.SPRINT else 5.5
		hv = Vector3(0.0, sin(Time.get_ticks_msec() * 0.001 * hz) * amp, 0.0)
	cam.position = hv

	_flashlight()
	_emit_noise(delta)


func _flashlight() -> void:
	flash.visible = Input.is_action_pressed("flashlight")


## How far a ghoul can hear this frame.
##
## This single number is the entire chase system. There is no health, no
## damage, and no weapon -- only this radius and whether the ghoul can see you.
func _emit_noise(delta: float) -> void:
	var r := InputSetup.noise_radius()
	if velocity.length() > 0.2 and r <= 0.0:
		r = 2.0   # crouch-walking is not silent, it is quiet
	_noise_accum += delta
	# Emit at 10 Hz, not per frame. A ghoul does not need 60 samples a second.
	if _noise_accum >= 0.1:
		_noise_accum = 0.0
		noise_emitted.emit(r)


func current_noise_radius() -> float:
	return InputSetup.noise_radius()


func teleport(x: float, y: float, z: float, yaw: float = 0.0) -> void:
	position = Vector3(x, y, z)
	rotation.y = yaw
	velocity = Vector3.ZERO
	_vel_y = 0.0


## Look at a world point. Used to point the player at the cake, the wardrobe,
## and the clock -- the game should never make the player hunt for a prop the
## script is talking about.
func look_at_point(p: Vector3) -> void:
	var dir := (p - head.global_position)
	if dir.length() < 0.001:
		return
	var target_yaw := atan2(-dir.x, -dir.z)
	var target_pitch := clampf(atan2(dir.y, Vector2(dir.x, dir.z).length()), -1.45, 1.45)
	rotation.y = target_yaw
	_pitch = target_pitch
	head.rotation.x = _pitch


func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED