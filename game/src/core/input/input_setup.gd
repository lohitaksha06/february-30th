extends Node
## InputMap setup, done in code rather than in the editor.
##
## Why not use the editor's Input Map panel:
##
##  1. It lives in project.godot, which does not merge cleanly between two
##     people working in parallel. This file does.
##  2. Touch input needs regions and dynamic buttons, which the static panel
##     cannot express. See docs/tech-stack.md §8.
##  3. The input layer is decided before the controller is written, so it
##     lives in reviewable source with a doc comment explaining each verb.
##
## All four held verbs are HOLD, never toggle. docs/tech-stack.md §8.3.

## Region of the virtual stick's outer ring that triggers sprint.
const SPRINT_RADIUS := 0.70
## Crouch button, left side. Above the stick, same thumb.
const CROUCH_RADIUS := 0.13
## Sprint button, right side.
const SPRINT_RADIUS_BTN := 0.11
## Flashlight, upper right.
const LIGHT_RADIUS := 0.09
## Interact -- centred, finger-agnostic, because it is used in conversation
## while both thumbs are busy holding things.
const INTERACT_RADIUS := 0.22

const DEADZONE := 0.22


func _ready() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_forward", [KEY_W, KEY_UP])
	_bind("move_back", [KEY_S, KEY_DOWN])

	# Crouch is C or right Ctrl, NOT Shift. Shift is not adjacent to WASD and
	# every keyboard player reaches for it as a modifier by reflex. The three
	# movement states must be reachable without moving the hand's home
	# position. docs/tech-stack.md §8.3.
	_bind("crouch", [KEY_C], JOY_BUTTON_A)

	# Sprint is Left Shift or Space.
	_bind("sprint", [KEY_SHIFT, KEY_SPACE], JOY_BUTTON_LEFT_STICK)

	_bind("flashlight", [KEY_F], JOY_BUTTON_RIGHT_SHOULDER)
	_bind("interact", [KEY_E, KEY_ENTER], JOY_BUTTON_X)
	_bind("dialogue_advance", [KEY_SPACE, KEY_ENTER, KEY_E])
	_bind("pause", [KEY_ESCAPE], JOY_BUTTON_START)

	# Analog movement axes, for a controller stick.
	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)

	_add_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)


func _bind(action: StringName, keys: Array, button: int = -1) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	if button >= 0:
		var jb := InputEventJoypadButton.new()
		jb.button_index = button
		InputMap.action_add_event(action, jb)


func _add_axis(action: StringName, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)


## Movement speed and noise, per state.
## docs/worlds.md -- there is no stamina bar; sprint is limited by geometry.
## Sprint is not a speed upgrade, it is the loudest thing in the game.
enum MoveState { CROUCH, WALK, SPRINT }

const SPEED := {
	MoveState.CROUCH: 0.6,
	MoveState.WALK: 1.8,
	MoveState.SPRINT: 4.2,
}

## How far a ghoul can hear each state. Metres. There is no combat and no
## weapon in this game, so this table is the entire chase system.
const NOISE := {
	MoveState.CROUCH: 0.0,
	MoveState.WALK: 6.0,
	MoveState.SPRINT: 22.0,
}

## The flashlight also makes noise. docs/worlds.md rule 4.
const LIGHT_NOISE_BONUS := 4.0


func current_state() -> int:
	if Input.is_action_pressed("crouch"):
		return MoveState.CROUCH
	if Input.is_action_pressed("sprint") or Input.get_axis("move_left", "move_right") > SPRINT_RADIUS:
		return MoveState.SPRINT
	return MoveState.WALK


## Emission radius this frame. A ghoul hears anything inside it.
func noise_radius() -> float:
	var r: float = NOISE[current_state()]
	if Input.is_action_pressed("flashlight"):
		r += LIGHT_NOISE_BONUS
	return r