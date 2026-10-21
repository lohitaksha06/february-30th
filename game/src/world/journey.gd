extends Node3D
## Shared director for the three 30th worlds (mushroom cave, blood cave,
## foggy street). One script, three geometries.
##
## Each geometry script exposes the same data contract:
##   spawn, exit_pos, exit_radius, hide_spots, hide_radius, checkpoints,
##   patrols, beats, objective, intro, next_scene, is_final, music_pitch
## so story coordinates and level coordinates cannot drift apart.
##
## It owns: stamina, chase music, hiding, checkpoints, respawn, beats,
## the world transition, and the street's goodbye.

enum S { PLAY, CAUGHT, LEAVING, FINALE, END }

@onready var player: Player = $Player
@onready var wren: Node3D = $Wren
@onready var geo = $Geometry
@onready var enemies_root: Node3D = $Enemies

var hud: JourneyHUD
var dlg: DialogueBox

var enemies: Array = []
var _spawn := Vector3.ZERO
var _exit := Vector3.ZERO
var _exit_radius := 2.0
var _hide_spots: Array = []
var _hide_radius := 1.8
var _checkpoints: Array = []
var _cp_idx := 0
var _beats: Array = []

var state: int = S.PLAY
var _grace_t := 0.0
var _caught_busy := false
## Tests set this false so transitions can be asserted without the test
## scene itself being replaced mid-run.
var allow_scene_change := true


func _ready() -> void:
	_spawn = geo.spawn
	_exit = geo.exit_pos
	_exit_radius = geo.exit_radius
	_hide_spots = geo.hide_spots
	_hide_radius = geo.hide_radius
	_checkpoints = geo.checkpoints
	_beats = geo.beats
	for b in _beats:
		b["done"] = false

	player.teleport(_spawn.x, _spawn.y, _spawn.z, 0.0)
	player.can_move = true
	player.stamina_enabled = true
	player.stamina = 1.0
	player.exhausted = false
	wren.call("follow", player)
	wren.global_position = _spawn + Vector3(-0.9, 0, 0.4)

	for i in range(enemies_root.get_child_count()):
		var e: Ghost = enemies_root.get_child(i) as Ghost
		if e == null:
			continue
		enemies.append(e)
		e.setup(player, self, geo.patrols[i % geo.patrols.size()])
		e.grace = true
	_grace_t = 1.2

	hud = JourneyHUD.new()
	add_child(hud)
	hud.setup(true)
	dlg = DialogueBox.new()
	hud.add_child(dlg)

	hud.fade.color.a = 1.0
	hud.fade_to(0.0, 2.2)
	hud.objective(str(geo.objective))
	hud.say(str(geo.intro))
	if geo.has_method("on_intro"):
		geo.call("on_intro")

	AudioDirector.play_world_drone(float(geo.music_pitch), -14.0)
	state = S.PLAY


# ---------------------------------------------------------------- frame

func _process(delta: float) -> void:
	if state == S.PLAY:
		_check_beats()
		_check_checkpoints()
		_update_prompt()
		_poll_chase_music()
		hud.set_stamina(player.stamina, player.exhausted)
		_check_exit()
		if _grace_t > 0.0:
			_grace_t -= delta
			if _grace_t <= 0.0:
				for e in enemies:
					e.grace = false


func _check_beats() -> void:
	var pp: Vector3 = player.global_position
	for b in _beats:
		if bool(b["done"]):
			continue
		var bp: Vector3 = b["pos"]
		pp.y = 0.0
		bp.y = 0.0
		if pp.distance_to(bp) < float(b["r"]):
			b["done"] = true
			for line in b["lines"]:
				hud.say(str(line))


func _check_checkpoints() -> void:
	if _cp_idx >= _checkpoints.size():
		return
	var pp: Vector3 = player.global_position
	var cp: Vector3 = _checkpoints[_cp_idx]
	pp.y = 0.0
	cp.y = 0.0
	if pp.distance_to(cp) < 2.5:
		_spawn = cp
		_cp_idx += 1


func _update_prompt() -> void:
	if is_player_hidden():
		hud.prompt("hidden — stay small, stay quiet")
		return
	if _any_chasing():
		hud.prompt("IT SEES YOU — RUN")
		return
	var pp: Vector3 = player.global_position
	var ex: Vector3 = _exit
	pp.y = 0.0
	ex.y = 0.0
	if pp.distance_to(ex) < _exit_radius and bool(geo.exit_requires_interact):
		hud.prompt("[E] go inside")
		return
	hud.prompt("")


func _poll_chase_music() -> void:
	if _any_chasing():
		AudioDirector.play_chase()
	else:
		AudioDirector.stop_chase()


func _any_chasing() -> bool:
	for e in enemies:
		if e.is_chasing():
			return true
	return false


func _check_exit() -> void:
	if state != S.PLAY:
		return
	var pp: Vector3 = player.global_position
	pp.y = 0.0
	var ex: Vector3 = _exit
	ex.y = 0.0
	if pp.distance_to(ex) >= _exit_radius:
		return
	if bool(geo.exit_requires_interact):
		if not Input.is_action_just_pressed("interact"):
			return
	_reach_exit()


## Crouched inside a marked spot: invisible. Same verb as Act 1.
func is_player_hidden() -> bool:
	if state != S.PLAY:
		return false
	if InputSetup.current_state() != InputSetup.MoveState.CROUCH:
		return false
	var pp: Vector3 = player.global_position
	for h in _hide_spots:
		var q: Vector3 = h
		pp.y = 0.0
		q.y = 0.0
		if pp.distance_to(q) < _hide_radius:
			return true
	return false


# ---------------------------------------------------------------- caught

func caught_by(_g: Ghost) -> void:
	if state != S.PLAY or _caught_busy:
		return
	_caught_busy = true
	state = S.CAUGHT
	AudioDirector.play_caught()
	hud.flash_sting(0.95)
	get_tree().paused = true
	await get_tree().create_timer(0.55, true, false, true).timeout
	get_tree().paused = false
	AudioDirector.stop_chase()
	hud.fade_to(1.0, 0.7)
	await get_tree().create_timer(1.0).timeout

	player.teleport(_spawn.x, _spawn.y, _spawn.z, 0.0)
	player.stamina = 1.0
	player.exhausted = false
	wren.global_position = _spawn + Vector3(-0.9, 0, 0.4)
	for e in enemies:
		e.reset()
		e.grace = true
	_grace_t = 3.0
	hud.clear_say()
	var line: Variant = geo.get("caught_line")
	hud.say(str(line) if line != null else "...dark. Then Wren's voice. \"Get up. It didn't keep you.\"")
	hud.fade_to(0.0, 1.5)
	state = S.PLAY
	_caught_busy = false


# ---------------------------------------------------------------- transitions

func _reach_exit() -> void:
	if bool(geo.is_final):
		_begin_finale()
	else:
		_next_world()


func _next_world() -> void:
	state = S.LEAVING
	player.can_move = false
	for e in enemies:
		e.active = false
	AudioDirector.stop_chase()
	hud.say("WREN: One more. Don't look back.")
	hud.fade_to(1.0, 1.3)
	await get_tree().create_timer(1.8).timeout
	AudioDirector.stop_music()
	if allow_scene_change:
		get_tree().change_scene_to_file(str(geo.next_scene))


## World 4 only. The door only knows one of us.
func _begin_finale() -> void:
	if state != S.PLAY:
		return
	state = S.FINALE
	player.can_move = false
	player.set_process_unhandled_input(false)  # hold the framing
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for e in enemies:
		e.active = false
	AudioDirector.stop_chase()
	hud.prompt("")
	player.look_at_point(_exit + Vector3(0, 1.4, 0))
	wren.global_position = player.global_position + Vector3(-1.0, 0, -1.2)

	dlg.show_lines("WREN", ["This is as far as I go.", "The door only knows one of us."])
	await dlg.line_finished
	dlg.show_choice("YOU", "", ["Come with me.", "I'll stay."])
	var picked: int = await dlg.option_chosen
	var answer: Array
	if picked == 1:
		answer = ["You can't. You have a birthday.", "Go. Tell her happy birthday."]
	else:
		answer = ["I can't. It isn't my house anymore.", "Go. Tell her happy birthday."]
	dlg.show_lines("WREN", answer)
	await dlg.line_finished
	dlg.show_lines("WREN", ["Go up. The cupboard's still open.", "Leave it that way. Just in case."])
	await dlg.line_finished

	hud.fade_to(1.0, 1.8)
	await get_tree().create_timer(2.1).timeout
	AudioDirector.stop_music()
	if allow_scene_change:
		get_tree().change_scene_to_file(str(geo.next_scene))
