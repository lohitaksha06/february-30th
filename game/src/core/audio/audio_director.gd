extends Node
## Tiny audio helper for Part 1. No mixing tricks, no bus layout needed.
## Just plays the generated wavs. Keeps PC load at zero.

var _knock: AudioStreamPlayer
var _lock: AudioStreamPlayer
var _music: AudioStreamPlayer
var _static: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_knock = _mk("Knock")
	_lock = _mk("Lock")
	_music = _mk("Music")
	_static = _mk("Static")
	_music.volume_db = -8.0
	_knock.volume_db = -2.0


func _mk(n: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = n
	p.bus = "Master"
	add_child(p)
	return p


func play_knock(times := 3, gap := 0.28) -> void:
	_knock.stream = load("res://assets/audio/knock.wav")
	for i in range(times):
		_knock.play()
		await get_tree().create_timer(gap).timeout
		# small pitch wobble so repeats feel wrong, not looped
		_knock.pitch_scale = 0.92 + randf() * 0.16


func play_lock() -> void:
	_lock.stream = load("res://assets/audio/door_lock.wav")
	_lock.pitch_scale = 1.0
	_lock.play()


func play_musicbox_30th() -> void:
	_music.stream = load("res://assets/audio/music_box_30th.wav")
	_music.pitch_scale = 1.0
	_music.play()


func play_musicbox_real() -> void:
	_music.stream = load("res://assets/audio/music_box_realmotif.wav")
	_music.pitch_scale = 1.0
	_music.play()


func stop_music() -> void:
	_music.stop()


## Cheap scare sting: knock pitched way down + short music stop.
## No DSP, just playback tricks. docs/art-direction.md §10: scares use removal.
func scare_hit() -> void:
	stop_music()
	_lock.stream = load("res://assets/audio/knock.wav")
	_lock.pitch_scale = 0.45
	_lock.volume_db = 6.0
	_lock.play()
	await get_tree().create_timer(0.6).timeout
	_lock.volume_db = 0.0
	_lock.pitch_scale = 1.0
