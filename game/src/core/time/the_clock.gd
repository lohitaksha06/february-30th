extends Node
## The 29th / 30th clock.
##
## There is exactly ONE clock object in the game and the whole confusion is a
## property of it, not scattered Time calls. docs/project-structure.md,
## module boundary rule 3.
##
## The date does not tick. It is set by script, and it only ever moves between
## two values: 29 and 30. The 30th reads in Act V and nowhere else.

signal minute_tick
signal hour_passed
signal date_changed(new_date: int)
signal midnight_reached

const DATE_29 := 29
const DATE_30 := 30

var hour: int = 11
var minute: int = 48
var date: int = DATE_29

## True once 12:00 has passed. The prologue's turn.
var past_midnight: bool = false

var _last_minute: int = -1


func _ready() -> void:
	_last_minute = minute
	process_mode = Node.PROCESS_MODE_ALWAYS


## Prologue beat 1: 11:48 when you wake up.
func set_time(h: int, m: int) -> void:
	hour = h
	minute = m
	_last_minute = m
	minute_tick.emit()


## Used by the prologue to make the wait at 11:59 feel like a wait without
## the player having to sit through eleven real minutes.
func advance_minutes(n: int) -> void:
	for _i in range(n):
		minute += 1
		if minute >= 60:
			minute = 0
			hour += 1
			if hour >= 24:
				roll_to_30th()
			else:
				hour_passed.emit()
		_last_minute = minute
		minute_tick.emit()


## Midnight. The date becomes the 30th.
##
## This is the only place DATE_30 is ever set. Everything else in the game
## reads it.
func roll_to_30th() -> void:
	hour = 0
	minute = 0
	if not past_midnight:
		past_midnight = true
		midnight_reached.emit()
	_set_date(DATE_30)


func _set_date(d: int) -> void:
	if date == d:
		return
	date = d
	date_changed.emit(date)


## Real-time tick. Only drives the HUD clock; gameplay time is script-driven.
func _process(delta: float) -> void:
	# Deliberately not advancing real time. See set_time().
	pass


## The HUD readout, which quietly disappears at some point during the
## conversation with Wren. docs/prologue.md beat 7 -- the theme is stated
## once, by omission, and never again.
var show_birthday: bool = true


func forget_birthday() -> void:
	if show_birthday:
		show_birthday = false


func hud_string() -> String:
	var t := "%02d:%02d" % [hour, minute]
	if not show_birthday:
		return t
	if date == DATE_30:
		return t
	return "FEB %d  %s" % [date, t]