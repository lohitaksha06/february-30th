extends Node
## Tests for Beat 7: the dialogue box and its branching tree.
## Run: godot --headless res://tests/test_dialogue.tscn
## Covers: typewriter + advance, option signals, keyboard cursor, every
## branch of the prologue tree resolving to a real node.

var _fails := 0


func _check(name: String, cond: bool) -> void:
	print("CHECK %s: %s" % [name, "PASS" if cond else "FAIL"])
	if not cond:
		_fails += 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _ready() -> void:
	# --- the box itself -------------------------------------------------
	var box := DialogueBox.new()
	get_tree().root.add_child.call_deferred(box)
	await get_tree().process_frame

	box.show_choice("WREN", "It's the thirtieth.", ["Are you OK?", "Are you in my cupboard?"])
	await _wait(0.1)
	_check("box_visible", box.visible)
	_check("box_shows_text", box._text_label.text.length() > 0)

	# Poll until the typewriter finishes; options must appear by themselves.
	var guard := 0
	while box._buttons.is_empty() and guard < 40:
		guard += 1
		await _wait(0.05)
	_check("box_options_shown", box._choices.size() == 2 and box._buttons.size() == 2)

	# Keyboard cursor moves and the highlighted option is the one emitted.
	box._set_sel(1)
	_check("box_cursor_moves", box._sel == 1)
	var picked := [-1]   # array: lambdas capture by value, arrays mutate
	box.option_chosen.connect(func(i: int): picked[0] = i)
	box._advance()
	await get_tree().process_frame
	_check("box_emits_option", picked[0] == 1)
	_check("box_closes_after_pick", not box.visible)

	# Line-only box: E through every line, then line_finished.
	var done := [false]
	box.line_finished.connect(func(): done[0] = true)
	box.show_lines("WREN", ["one", "two"])
	await _wait(0.1)
	var g2 := 0
	while box.visible and g2 < 20:
		g2 += 1
		box._advance()
		await _wait(0.05)
	_check("box_lines_finish", done[0])

	# --- the prologue's actual tree -------------------------------------
	var pro: Node = load("res://scenes/prologue.tscn").instantiate()
	get_tree().root.add_child.call_deferred(pro)
	await get_tree().process_frame
	var errors: Array = pro.call("validate_dialogue_tree")
	_check("tree_valid", errors.is_empty())
	if not errors.is_empty():
		for e in errors:
			print("  tree error: ", e)

	# Every node must terminate: following the first branch always reaches
	# a node with no "next", so no choice can dead-end the conversation.
	var tree: Dictionary = pro._DLG
	var terminates := true
	for id in tree.keys():
		var cur: String = str(id)
		var guard2 := 0
		while cur != "" and guard2 < 60:
			guard2 += 1
			var n: Dictionary = tree[cur]
			if not n.has("next"):
				break
			var nxt: Variant = n["next"]
			if nxt is Array:
				var arr: Array = nxt
				cur = str(arr[0]) if not arr.is_empty() else ""
			else:
				cur = str(nxt)
		if guard2 >= 60:
			terminates = false
			print("  possible loop at ", id)
	_check("tree_terminates", terminates)
	_check("tree_has_mum_sting", tree.has("mumsting"))
	_check("tree_sting_three_lines", (tree["mumsting"]["lines"] as Array).size() == 3)

	print("SMOKE %s (%d fails)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(_fails)
