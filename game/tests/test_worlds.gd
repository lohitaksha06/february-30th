extends Node
## Headless smoke test for the three 30th worlds + the morning ending.
## Run: godot --headless res://tests/test_worlds.tscn
##
## Per cave world: boots, hide works, chase triggers + music, caught/respawn,
## exit enters LEAVING (scene change disabled under test).
## Street: is final, finale dialogue starts, Wren is present.
## Ending: boots, no stamina bar, going downstairs shows the card.

var _fails := 0


func _check(name: String, cond: bool) -> void:
	print("CHECK %s: %s" % [name, "PASS" if cond else "FAIL"])
	if not cond:
		_fails += 1


func _boot(path: String) -> Node3D:
	var inst: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	# Keep the test scene alive: assert transitions without swapping scenes.
	inst.set("allow_scene_change", false)
	get_tree().root.add_child.call_deferred(inst)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.6).timeout
	return inst


func _force_chase(w: Node3D, geo) -> bool:
	var player: CharacterBody3D = w.get_node("Player") as CharacterBody3D
	var enemy: CharacterBody3D = w.get_node("Enemies").get_child(0) as CharacterBody3D
	# Stand both actors on the first path segment: guaranteed walkable,
	# guaranteed clear line of sight, regardless of where patrols started.
	var path: Array = geo.PATH
	var a: Vector3 = path[0]
	var b: Vector3 = path[1]
	var dir: Vector3 = (b - a).normalized()
	var yaw := atan2(-dir.x, -dir.z)
	for i in range(60):
		enemy.global_position = a + dir * 1.2 + Vector3(0, 0.1, 0)
		enemy.rotation.y = yaw
		enemy.velocity = Vector3.ZERO
		var p: Vector3 = a + dir * 3.7
		player.call("teleport", p.x, 0.1, p.z, yaw + PI)
		await get_tree().create_timer(0.1).timeout
		if int(enemy.get("state")) == Ghost.G.CHASE:
			return true
	return false


func _test_cave(path: String, tag: String, expect_crawler: bool) -> void:
	var w := await _boot(path)
	var player: CharacterBody3D = w.get_node("Player") as CharacterBody3D
	var geo = w.get_node("Geometry")
	var enemies: Array = w.get_node("Enemies").get_children()

	_check(tag + "_boots", is_instance_valid(player) and w.get("hud") != null)
	_check(tag + "_enemy_count", enemies.size() >= 2)
	_check(tag + "_enemy_active", bool(enemies[0].get("active")))
	if expect_crawler:
		_check(tag + "_crawler_type", enemies[0] is Crawler)

	# Hide: crouched in a marked hollow is invisible.
	var hide: Vector3 = (geo.hide_spots as Array)[0]
	player.call("teleport", hide.x, 0.1, hide.z, 0.0)
	Input.action_press("crouch")
	await get_tree().create_timer(0.4).timeout
	_check(tag + "_hide_works", bool(w.call("is_player_hidden")))
	Input.action_release("crouch")
	await get_tree().create_timer(0.2).timeout

	# Chase: it sees you in the open and the loop starts.
	var chased := await _force_chase(w, geo)
	_check(tag + "_chase_triggers", chased)
	_check(tag + "_chase_music", AudioDirector._chase.playing)

	# Catch: stand on it -> caught state, then respawn at the checkpoint.
	var enemy: CharacterBody3D = w.get_node("Enemies").get_child(0) as CharacterBody3D
	var gp: Vector3 = enemy.global_position + Vector3(0.8, 0, 0)
	player.call("teleport", gp.x, 0.1, gp.z, 0.0)
	var caught := false
	for i in range(50):
		await get_tree().create_timer(0.1).timeout
		if int(w.get("state")) == 1:  # journey S.CAUGHT
			caught = true
			break
	_check(tag + "_caught", caught)
	for i in range(70):
		await get_tree().create_timer(0.1).timeout
		if int(w.get("state")) == 0:  # back to S.PLAY
			break
	var pp: Vector3 = player.global_position
	var spawn: Vector3 = geo.spawn
	_check(tag + "_respawn", pp.distance_to(spawn) < 2.0)

	# Exit -> LEAVING. Scene change is disabled, so assert the state.
	var ex: Vector3 = geo.exit_pos
	player.call("teleport", ex.x, 0.1, ex.z, 0.0)
	Input.action_press("interact")
	await get_tree().process_frame
	Input.action_release("interact")
	await get_tree().create_timer(0.4).timeout
	_check(tag + "_exit_leaves", int(w.get("state")) == 2)  # S.LEAVING
	_check(tag + "_next_scene_exists", ResourceLoader.exists(str(geo.next_scene)))

	# Let the (disabled) transition coroutine finish before freeing.
	await get_tree().create_timer(1.9).timeout
	AudioDirector.stop_chase()
	w.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	await _test_cave("res://scenes/world2_mushrooms.tscn", "w2", true)
	await _test_cave("res://scenes/world3_blood.tscn", "w3", false)

	# --- street ---------------------------------------------------------
	var street := await _boot("res://scenes/world4_street.tscn")
	var splayer: CharacterBody3D = street.get_node("Player") as CharacterBody3D
	var sgeo = street.get_node("Geometry")
	_check("w4_boots", is_instance_valid(splayer) and street.get("hud") != null)
	_check("w4_is_final", bool(sgeo.is_final))
	_check("w4_door_needs_interact", bool(sgeo.exit_requires_interact))
	_check("w4_wren_present", street.get_node_or_null("Wren") != null)
	_check("w4_two_enemies", street.get_node("Enemies").get_child_count() == 2)

	# The goodbye starts at the door and freezes the player.
	street.call("_reach_exit")
	await get_tree().create_timer(0.4).timeout
	_check("w4_finale_state", int(street.get("state")) == 3)  # S.FINALE
	_check("w4_finale_dialogue", bool(street.get("dlg").visible))
	_check("chain_w4_ending_exists",
		ResourceLoader.exists("res://scenes/ending.tscn"))
	street.queue_free()
	await get_tree().process_frame

	# --- ending ---------------------------------------------------------
	var ending: Node3D = (load("res://scenes/ending.tscn") as PackedScene).instantiate() as Node3D
	get_tree().root.add_child.call_deferred(ending)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	var ehud = ending.get("hud")
	_check("end_boots", ehud != null)
	_check("end_no_stamina_bar", ehud != null and not bool(ehud.get("_has_stamina")))
	await get_tree().create_timer(0.3).timeout
	ending.call("_go_downstairs")
	await get_tree().create_timer(1.8).timeout
	_check("end_card", int(ending.get("state")) == 1 and bool(ehud.card.visible))
	_check("end_has_title", "FEBRUARY 29th" in str(ehud.card_label.text))

	print("SMOKE %s (%d fails)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(_fails)
