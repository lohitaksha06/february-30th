extends Node
## Tiny audio helper for Part 1. No mixing tricks, no bus layout needed.
## Just plays the generated wavs. Keeps PC load at zero.

var _knock: AudioStreamPlayer
var _lock: AudioStreamPlayer
var _music: AudioStreamPlayer
var _static: AudioStreamPlayer
var _chase: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_knock = _mk("Knock")
	_lock = _mk("Lock")
	_music = _mk("Music")
	_static = _mk("Static")
	_chase = _mk("Chase")
	_music.volume_db = -8.0
	_knock.volume_db = -2.0
	_chase.volume_db = -4.0


func _mk(n: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = n
	p.bus = "Master"
	add_child(p)
	return p


## Fresh clones may lack generated wavs (game/assets/audio/ is git-ignored
## build output). Never crash on that -- play silence instead.
func _load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func play_knock(times := 3, gap := 0.28) -> void:
	var s := _load("res://assets/audio/knock.wav")
	if s == null:
		return
	_knock.stream = s
	for i in range(times):
		_knock.play()
		await get_tree().create_timer(gap).timeout
		# small pitch wobble so repeats feel wrong, not looped
		_knock.pitch_scale = 0.92 + randf() * 0.16


func play_lock() -> void:
	var s := _load("res://assets/audio/door_lock.wav")
	if s == null:
		return
	_lock.stream = s
	_lock.pitch_scale = 1.0
	_lock.play()


func play_musicbox_30th() -> void:
	var s := _load("res://assets/audio/music_box_30th.wav")
	if s == null:
		return
	_music.stream = s
	_music.pitch_scale = 1.0
	_music.play()


func play_musicbox_real() -> void:
	var s := _load("res://assets/audio/music_box_realmotif.wav")
	if s == null:
		return
	_music.stream = s
	_music.pitch_scale = 1.0
	_music.play()


func stop_music() -> void:
	_music.stop()


## Cheap scare sting: knock pitched way down + short music stop.
## No DSP, just playback tricks. docs/art-direction.md §10: scares use removal.
func scare_hit() -> void:
	stop_music()
	stop_chase()
	var s := _load("res://assets/audio/knock.wav")
	if s == null:
		return
	_lock.stream = s
	_lock.pitch_scale = 0.45
	_lock.volume_db = 6.0
	_lock.play()
	await get_tree().create_timer(0.6).timeout
	_lock.volume_db = 0.0
	_lock.pitch_scale = 1.0


## Act 1: cavern drone (slow motif under everything) + chase loop.
func play_cavern_drone() -> void:
	var s := _load("res://assets/audio/music_box_slow.wav")
	if s == null:
		return
	_music.stream = s
	_music.pitch_scale = 0.7
	_music.volume_db = -14.0
	_music.play()


func restore_music_volume() -> void:
	_music.volume_db = -8.0


func play_chase() -> void:
	if _chase.playing:
		return
	var s := _load("res://assets/audio/chase_loop.wav")
	if s == null:
		return
	_chase.stream = s
	_chase.pitch_scale = 1.0
	_chase.play()


func stop_chase() -> void:
	_chase.stop()


func play_caught() -> void:
	var s := _load("res://assets/audio/caught_sting.wav")
	if s == null:
		return
	_static.stream = s
	_static.pitch_scale = 1.0
	_static.volume_db = 2.0
	_static.play()
