extends Node
## Headless smoke test for Act 1. Not a unit test -- it plays the level:
## chase trigger, touch catch + respawn, hide escape, exit ending.
## Run: godot --headless res://tests/test_act1.tscn
## Prints CHECK lines and quits with code 0 (all pass) or 1.

var _fails := 0


func _check(name: String, cond: bool) -> void:
	print("CHECK %s: %s" % [name, "PASS" if cond else "FAIL"])
	if not cond:
		_fails += 1


## Pin both actors on open path (no rocks, no checkpoints nearby) until it
## chases. Re-pinned every poll: deterministic regardless of patrol phase.
func _force_chase(player: CharacterBody3D, ghost: CharacterBody3D) -> bool:
	for i in range(60):
		ghost.global_position = Vector3(0, 0.1, -6)
		ghost.rotation.y = 0.0
		ghost.velocity = Vector3.ZERO
		player.call("teleport", 0.0, 0.1, -9.5, 0.0)
		await get_tree().create_timer(0.1).timeout
		if int(ghost.get("state")) == Ghost.G.CHASE:
			return true
	return false


func _ready() -> void:
	var cav: Node3D = load("res://scenes/cavern.tscn").instantiate() as Node3D
	get_tree().root.add_child.call_deferred(cav)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(1.0).timeout

	var player: CharacterBody3D = cav.get_node("Player") as CharacterBody3D
	var ghost_a: CharacterBody3D = cav.get_node("GhostA") as CharacterBody3D
	_check("stage_boots", is_instance_valid(player) and bool(ghost_a.get("active")))

	# 1. In its face -> chase, and the eerie loop starts.
	_check("ghost_chases_on_sight", await _force_chase(player, ghost_a))
	_check("chase_music_plays", AudioDirector._chase.playing)

	# 2. Step onto it while it chases -> caught, respawned at entry.
	# NOTE: offset 0.8 m, not exact overlap -- teleporting inside a
	# capsule ejects the rider upward and they end up standing on its
	# head, out of catch range. (Found by this test. Real play collides.)
	var gp: Vector3 = ghost_a.global_position + Vector3(0.8, 0, 0)
	player.call("teleport", gp.x, 0.1, gp.z, 0.0)
	var caught := false
	for i in range(40):
		await get_tree().create_timer(0.1).timeout
		if int(cav.get("state")) == 2:  # S.CAUGHT
			caught = true
			break
	_check("touch_caught", caught)
	for i in range(60):
		await get_tree().create_timer(0.1).timeout
		if int(cav.get("state")) == 1:  # back to S.PLAY after respawn
			break
	var pp: Vector3 = player.global_position
	_check("respawn_at_checkpoint", pp.distance_to(Vector3(0, 0.1, 2)) < 1.0)

	# 3. Grace expires -> chase again -> hollow + crouch -> it gives up.
	await get_tree().create_timer(3.5).timeout
	_check("ghost_rechases", await _force_chase(player, ghost_a))
	player.call("teleport", 3.4, 0.1, -10.5, 0.0)
	Input.action_press("crouch")
	var escaped := false
	for i in range(90):
		await get_tree().create_timer(0.1).timeout
		var st := int(ghost_a.get("state"))
		if st == Ghost.G.SEARCH or st == Ghost.G.PATROL:
			escaped = true
			break
	Input.action_release("crouch")
	_check("ghost_loses_hidden_player", escaped)

	# 4. Walk into the white door -> ending.
	player.call("teleport", 0.0, 0.1, -37.0, 0.0)
	await get_tree().create_timer(1.0).timeout
	_check("exit_end_card", int(cav.get("state")) == 3)  # S.END

	print("SMOKE %s (%d fails)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(_fails)
