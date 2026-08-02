extends AudioStreamPlayer
class_name ProceduralAudioManager

const MIX_RATE := 22050.0
const BUFFER_LENGTH := 0.35

var audio_enabled := false
var desired_volume := 0.6
var playback: AudioStreamGeneratorPlayback
var sample_cursor := 0


func set_audio_enabled(enabled: bool) -> void:
	audio_enabled = enabled
	if not audio_enabled:
		stop()
		playback = null
		set_process(false)
		return
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	if stream == null:
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = MIX_RATE
		generator.buffer_length = BUFFER_LENGTH
		stream = generator
	volume_db = linear_to_db(maxf(desired_volume, 0.001))
	if not playing:
		play()
	playback = get_stream_playback() as AudioStreamGeneratorPlayback
	set_process(true)


func set_audio_volume(value: float) -> void:
	desired_volume = clampf(value, 0.0, 1.0)
	volume_db = linear_to_db(maxf(desired_volume, 0.001))


func is_audio_active() -> bool:
	return audio_enabled and (playing or DisplayServer.get_name() == "headless")


func _ready() -> void:
	set_process(false)


func _exit_tree() -> void:
	stop()
	playback = null
	stream = null
	set_process(false)


func _process(_delta: float) -> void:
	if playback == null:
		return
	var frames := playback.get_frames_available()
	for frame_index in range(frames):
		var time := float(sample_cursor) / MIX_RATE
		var breeze := 0.55 + 0.45 * sin(time * 0.37)
		var sample := (
			sin(TAU * 174.0 * time) * 0.018
			+ sin(TAU * 261.63 * time + 0.7) * 0.011
			+ sin(TAU * 349.23 * time + 1.4) * 0.007
		) * breeze
		playback.push_frame(Vector2(sample, sample * 0.96))
		sample_cursor += 1
