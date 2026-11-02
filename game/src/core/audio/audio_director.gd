extends Node
## Tiny audio helper for Part 1. No mixing tricks, no bus layout needed.
## Just plays the generated wavs. Keeps PC load at zero.
##
## The prologue's audio arc, in order:
##   bedroom bed (a house at night, one band missing)
##   the music box, in tune, in the living room  [the only warm sound]
##   it stops mid-phrase  ->  four seconds of nothing
##   knocks + the wardrobe starting to breathe
##   midnight: the box returns, flat and slow
##   the bad cheer, far away, under the title
##
## docs/art-direction.md §9: 70% of the fear budget is audio. This file is
## where that budget is spent.

var _knock: AudioStreamPlayer
var _lock: AudioStreamPlayer
var _music: AudioStreamPlayer
var _static: AudioStreamPlayer
var _chase: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _creak: AudioStreamPlayer
var _dread: AudioStreamPlayer
var _cheer: AudioStreamPlayer
var _heart: AudioStreamPlayer

var _music_tw: Tween
var _amb_tw: Tween
var _heart_tw: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_knock = _mk("Knock")
	_lock = _mk("Lock")
	_music = _mk("Music")
	_static = _mk("Static")
	_chase = _mk("Chase")
	_ambience = _mk("Ambience")
	_creak = _mk("Creak")
	_dread = _mk("Dread")
	_cheer = _mk("Cheer")
	_heart = _mk("Heart")
	_music.volume_db = -8.0
	_knock.volume_db = -2.0
	_chase.volume_db = -4.0
	_ambience.volume_db = -40.0
	_creak.volume_db = -5.0
	_dread.volume_db = -10.0
	_cheer.volume_db = -16.0
	_heart.volume_db = -60.0


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


## Loop an imported wav without touching the .import file. AudioStreamWAV
## stores 16-bit mono, so loop_end is the byte count / 2.
func _load_loop(path: String) -> AudioStream:
	var s := _load(path)
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = w.data.size() / 2
	return s


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


## The room tone. Starts in the bedroom and runs under the whole prologue.
## It is deliberately almost inaudible: the absence of a band is the effect.
func play_ambience() -> void:
	var s := _load_loop("res://assets/audio/prologue_bed.wav")
	if s == null:
		return
	_ambience.stream = s
	_ambience.volume_db = -40.0
	_ambience.play()
	if _amb_tw != null and _amb_tw.is_valid():
		_amb_tw.kill()
	_amb_tw = create_tween()
	_amb_tw.tween_property(_ambience, "volume_db", -11.0, 4.0)


func stop_ambience(fade := 2.0) -> void:
	if not _ambience.playing:
		return
	if _amb_tw != null and _amb_tw.is_valid():
		_amb_tw.kill()
	_amb_tw = create_tween()
	_amb_tw.tween_property(_ambience, "volume_db", -50.0, fade)
	_amb_tw.tween_callback(_ambience.stop)


## Take the room tone out for the four-second gap in Beat 4, then bring it
## back. The silence only reads as silence if the bed goes with it.
func duck_ambience(fade := 0.6) -> void:
	if not _ambience.playing:
		return
	if _amb_tw != null and _amb_tw.is_valid():
		_amb_tw.kill()
	_amb_tw = create_tween()
	_amb_tw.tween_property(_ambience, "volume_db", -42.0, fade)


func un_duck_ambience(fade := 1.2) -> void:
	if not _ambience.playing:
		return
	if _amb_tw != null and _amb_tw.is_valid():
		_amb_tw.kill()
	_amb_tw = create_tween()
	_amb_tw.tween_property(_ambience, "volume_db", -11.0, fade)


## A single wardrobe hinge. One of the few sounds that should be *close*.
func play_creak() -> void:
	var s := _load("res://assets/audio/wardrobe_creak.wav")
	if s == null:
		return
	_creak.stream = s
	_creak.pitch_scale = 0.92 + randf() * 0.1
	_creak.play()


## Something in the room changes. Rising, unresolved, cut before it lands.
func play_dread() -> void:
	var s := _load("res://assets/audio/dread_rise.wav")
	if s == null:
		return
	_dread.stream = s
	_dread.play()


## A slow heartbeat under the knocks. Starts quiet enough that the player
## cannot say when it began; docs/art-direction.md §10.
func play_heartbeat() -> void:
	var s := _load_loop("res://assets/audio/heartbeat.wav")
	if s == null:
		return
	_heart.stream = s
	_heart.volume_db = -34.0
	_heart.play()
	if _heart_tw != null and _heart_tw.is_valid():
		_heart_tw.kill()
	_heart_tw = create_tween()
	_heart_tw.tween_property(_heart, "volume_db", -17.0, 4.0)


func raise_heartbeat(level := -9.0, fade := 2.0) -> void:
	if not _heart.playing:
		return
	if _heart_tw != null and _heart_tw.is_valid():
		_heart_tw.kill()
	_heart_tw = create_tween()
	_heart_tw.tween_property(_heart, "volume_db", level, fade)


func stop_heartbeat(fade := 2.0) -> void:
	if not _heart.playing:
		return
	if _heart_tw != null and _heart_tw.is_valid():
		_heart_tw.kill()
	_heart_tw = create_tween()
	_heart_tw.tween_property(_heart, "volume_db", -60.0, fade)
	_heart_tw.tween_callback(_heart.stop)


func play_musicbox_30th() -> void:
	var s := _load("res://assets/audio/music_box_30th.wav")
	if s == null:
		return
	if _music_tw != null and _music_tw.is_valid():
		_music_tw.kill()
	_music.stream = s
	_music.pitch_scale = 0.97
	_music.volume_db = -9.0
	_music.play()


func play_musicbox_real() -> void:
	var s := _load("res://assets/audio/music_box_realmotif.wav")
	if s == null:
		return
	if _music_tw != null and _music_tw.is_valid():
		_music_tw.kill()
	_music.stream = s
	_music.pitch_scale = 1.0
	_music.volume_db = -7.0
	_music.play()


func stop_music(fade := 0.0) -> void:
	if _music_tw != null and _music_tw.is_valid():
		_music_tw.kill()
	if fade <= 0.0:
		_music.stop()
		return
	_music_tw = create_tween()
	_music_tw.tween_property(_music, "volume_db", -45.0, fade)
	_music_tw.tween_callback(_music.stop)


## The bad cheer: a party played slightly out of time with itself.
## docs/art-direction.md §10 calls it the most important cue in the game.
func play_bad_cheer(far := true) -> void:
	var s := _load("res://assets/audio/bad_cheer_far.wav" if far
		else "res://assets/audio/bad_cheer_near.wav")
	if s == null:
		return
	_cheer.stream = s
	_cheer.volume_db = -20.0 if far else -6.0
	_cheer.play()


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


## Same motif, different room. Pitch is the whole world's mood knob:
## bright cave ~0.85, red cave ~0.55, street ~0.95.
func play_world_drone(pitch := 0.7, vol := -14.0) -> void:
	var s := _load("res://assets/audio/music_box_slow.wav")
	if s == null:
		return
	_music.stream = s
	_music.pitch_scale = pitch
	_music.volume_db = vol
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
