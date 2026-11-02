extends Node
## Headless smoke test for the prologue's new beat order:
## wake slowly -> check the clock -> see the cake -> knocks -> pause menu.
## Run: godot --headless res://tests/test_prologue.tscn

var _fails := 0


func _check(name: String, cond: bool) -> void:
	print("CHECK %s: %s" % [name, "PASS" if cond else "FAIL"])
	if not cond:
		_fails += 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _ready() -> void:
	var pro: Node3D = load("res://scenes/prologue.tscn").instantiate() as Node3D
	get_tree().root.add_child.call_deferred(pro)
	await get_tree().process_frame
	await get_tree().process_frame

	_check("scene_loaded", pro != null)
	_check("starts_in_select", int(pro.get("state")) == 0)
	_check("clock_starts_1159", Clock.hour == 11 and Clock.minute == 59)
	_check("mouse_visible_for_select", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)

	# Pick a character. This starts the slow wake.
	pro.call("_on_pick", "girl")
	await _wait(0.2)
	_check("lying_after_pick", int(pro.get("state")) == 1)
	_check("physics_held_in_bed", not (pro.get("player") as CharacterBody3D).is_physics_processing())
	_check("wake_not_ready_immediately", not bool(pro.get("_wake_ready")))
	var wake_cam: Camera3D = (pro.get("player") as Node).get_node("Head/Camera3D") as Camera3D
	_check("lying_eye_near_mattress", wake_cam.global_position.y < 1.2)
	_check("wardrobe_door_found", pro.get("_door") != null)

	# The wake prompt must wait for the slow fade, not appear instantly.
	await _wait(3.8)
	_check("wake_ready", bool(pro.get("_wake_ready")))

	pro.call("_sit_up")
	await _wait(3.2)
	_check("clock_state_after_situp", int(pro.get("state")) == 3)
	_check("physics_back_on", (pro.get("player") as CharacterBody3D).is_physics_processing())
	_check("can_move_after_situp", (pro.get("player") as CharacterBody3D).can_move)
	_check("clock_label_1159", (pro.get("clock3d") as Label3D).text == "11:59")

	# Check the clock. This is the "one more minute" beat.
	pro.call("_check_clock")
	await _wait(3.5)
	_check("living_state_after_clock", int(pro.get("state")) == 4)
	_check("still_1159", Clock.hour == 11 and Clock.minute == 59)

	# Walk to the cake (teleport is enough for the trigger).
	var player: CharacterBody3D = pro.get("player")
	player.teleport(5.6, 0.1, 1.8, 0.0)
	await _wait(0.3)
	_check("cake_seen", bool(pro.get("_seen_cake")))
	await _wait(2.6)
	_check("explore_after_cake", int(pro.get("state")) == 5)

	# Knocks -> KNOCK state and the wardrobe prompt. Beat 4 now holds a real
	# four-second gap before the rustling starts, so the test checks both.
	pro.call("_start_knocks")
	await _wait(3.6)
	_check("knock_state", int(pro.get("state")) == 6)
	_check("knock_silence", not bool(pro.get("_knock_ready")))
	await _wait(4.2)
	_check("knock_ready", bool(pro.get("_knock_ready")))
	_check("wardrobe_dread_on", bool((pro.get("_house") as Node).get("_dread")))

	# Wren is in front of the wardrobe, not inside its solid mesh.
	var wren: Node3D = pro.get("wren")
	_check("wren_in_front_of_wardrobe", wren.global_position.z > 1.0)

	# ESC menu pauses, frees the mouse, and restores both.
	var pause: Node = pro.get("_pause")
	pause.call("open")
	await get_tree().process_frame
	_check("pause_opens", get_tree().paused)
	_check("pause_visible", (pause as CanvasItem).visible)
	pause.call("close")
	await get_tree().process_frame
	_check("pause_closes", not get_tree().paused)
	_check("pause_hidden", not (pause as CanvasItem).visible)

	# The post-fall card must name Act I and invite ENTER, not read as an end.
	# Run the real fall path, not _show_title directly: the old capture hung
	# here, so this is the check that proves the prologue can reach Act I.
	pro.call("_start_fall")
	await _wait(5.6)
	_check("fall_reaches_title", int(pro.get("state")) == 11)
	_check("title_state", int(pro.get("state")) == 11)
	_check("title_act1", (pro.get("_title_sub") as Label).text.contains("ACT I"))
	_check("title_continue_prompt", (pro.get("_prompt") as Label).text.contains("ENTER"))

	print("SMOKE %s (%d fails)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(_fails)
