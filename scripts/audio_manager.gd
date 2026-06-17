extends Node

const MUSIC_PATHS := {
	"menu": "res://assets/audio/music_menu.wav",
	"dungeon": "res://assets/audio/music_dungeon.wav",
	"boss": "res://assets/audio/music_boss.wav",
	"ending": "res://assets/audio/music_ending.wav",
}

const SFX_PATHS := {
	"shoot": "res://assets/audio/sfx_shoot.wav",
	"hit": "res://assets/audio/sfx_hit.wav",
	"enemy_death": "res://assets/audio/sfx_enemy_death.wav",
	"door": "res://assets/audio/sfx_door.wav",
	"pickup": "res://assets/audio/sfx_pickup.wav",
	"shield": "res://assets/audio/sfx_shield.wav",
	"boss_roar": "res://assets/audio/sfx_boss_roar.wav",
}

const MUSIC_VOLUME_DB := 6.0

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_track := ""


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = &"Master"
	_music_player.volume_db = MUSIC_VOLUME_DB
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

	for index in 4:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % index
		player.bus = &"Master"
		add_child(player)
		_sfx_players.append(player)


func _load_music_stream(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		push_error("GameAudio: missing music file '%s'" % path)
		return null

	# Imported music used loop_mode=Forward with an invalid loop_end, which can
	# play silence while still reporting playing=true. Load with looping disabled
	# and restart manually in _on_music_finished().
	var stream: AudioStream = AudioStreamWAV.load_from_file(
		path,
		{
			"edit/loop_mode": 0,
			"compress/mode": 0,
		}
	)
	if stream == null:
		stream = load(path)
	if stream == null:
		return null

	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED

	return stream


func play_music(track_name: String, _fade_in := 0.5) -> void:
	if _music_player == null:
		return

	var path: String = MUSIC_PATHS.get(track_name, "")
	if path.is_empty():
		push_warning("GameAudio: unknown music track '%s'" % track_name)
		return

	var stream := _load_music_stream(path)
	if stream == null:
		push_error("GameAudio: failed to load music '%s'" % path)
		return

	_current_track = track_name
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = MUSIC_VOLUME_DB
	_music_player.play()


func stop_music(_fade_out := 0.35) -> void:
	_current_track = ""
	if _music_player != null:
		_music_player.stop()


func _on_music_finished() -> void:
	if _current_track.is_empty() or _music_player == null:
		return
	_music_player.play()


func play_sfx(sfx_name: String, pitch_scale := 1.0) -> void:
	if _sfx_players.is_empty():
		return

	var path: String = SFX_PATHS.get(sfx_name, "")
	if path.is_empty():
		push_warning("GameAudio: unknown sfx '%s'" % sfx_name)
		return

	var stream: AudioStream = load(path)
	if stream == null:
		push_error("GameAudio: failed to load sfx '%s'" % path)
		return

	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.play()
			return

	_sfx_players[0].stop()
	_sfx_players[0].stream = stream
	_sfx_players[0].pitch_scale = pitch_scale
	_sfx_players[0].play()
