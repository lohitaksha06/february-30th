extends Node
## Global run flags for Part 1 (prologue: wake -> fall).
## Kept flat on purpose. Save file is JSON, see docs/tech-stack.md §9.

var in_bed: bool = true
var sat_up: bool = false
var heard_knock: bool = false
var met_wren: bool = false
var pushed: bool = false
var falling: bool = false
var finished: bool = false

var gender: String = "boy"  # set by character select, Wren copies it


func reset_prologue() -> void:
	in_bed = true
	sat_up = false
	heard_knock = false
	met_wren = false
	pushed = false
	falling = false
	finished = false
