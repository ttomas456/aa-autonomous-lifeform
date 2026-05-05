extends RefCounted
class_name ProceduralSound

const MIX_RATE := 22050
const INT16_SCALE := 32767.0


static func make_tone(frequency: float, duration: float, volume := 0.16, wobble := 0.0) -> AudioStreamWAV:
	return make_phrase([
		{
			"frequency": frequency,
			"duration": duration,
			"volume": volume,
			"wobble": wobble
		}
	])


static func make_bark(personality_pitch := 1.0) -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 165.0 * personality_pitch, "end_frequency": 92.0 * personality_pitch, "duration": 0.105, "volume": 0.24, "wobble": 18.0, "noise": 0.58, "waveform": "square"},
		{"duration": 0.035, "volume": 0.0},
		{"frequency": 205.0 * personality_pitch, "end_frequency": 115.0 * personality_pitch, "duration": 0.095, "volume": 0.19, "wobble": 24.0, "noise": 0.46, "waveform": "square"}
	])


static func make_happy_yip(personality_pitch := 1.0) -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 560.0 * personality_pitch, "end_frequency": 820.0 * personality_pitch, "duration": 0.070, "volume": 0.14, "wobble": 90.0, "noise": 0.08, "waveform": "sine"},
		{"duration": 0.025, "volume": 0.0},
		{"frequency": 720.0 * personality_pitch, "end_frequency": 980.0 * personality_pitch, "duration": 0.060, "volume": 0.12, "wobble": 110.0, "noise": 0.05, "waveform": "sine"}
	])


static func make_whine(personality_pitch := 1.0) -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 380.0 * personality_pitch, "end_frequency": 520.0 * personality_pitch, "duration": 0.24, "volume": 0.10, "wobble": 85.0, "noise": 0.03, "waveform": "sine"}
	])


static func make_chew() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 120.0, "duration": 0.050, "volume": 0.11, "wobble": 20.0, "noise": 0.72, "waveform": "noise"},
		{"duration": 0.035, "volume": 0.0},
		{"frequency": 96.0, "duration": 0.047, "volume": 0.10, "wobble": 18.0, "noise": 0.76, "waveform": "noise"},
		{"duration": 0.030, "volume": 0.0},
		{"frequency": 132.0, "duration": 0.043, "volume": 0.09, "wobble": 24.0, "noise": 0.66, "waveform": "noise"}
	])


static func make_toy_squeak() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 1180.0, "end_frequency": 1780.0, "duration": 0.080, "volume": 0.13, "wobble": 210.0, "noise": 0.02, "waveform": "square"},
		{"frequency": 1500.0, "end_frequency": 820.0, "duration": 0.095, "volume": 0.10, "wobble": 170.0, "noise": 0.03, "waveform": "square"}
	])


static func make_snore() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 74.0, "end_frequency": 105.0, "duration": 0.36, "volume": 0.065, "wobble": 8.0, "noise": 0.26, "waveform": "sine"},
		{"duration": 0.08, "volume": 0.0},
		{"frequency": 105.0, "end_frequency": 66.0, "duration": 0.28, "volume": 0.055, "wobble": 7.0, "noise": 0.24, "waveform": "sine"}
	])


static func make_whistle() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 880.0, "end_frequency": 1720.0, "duration": 0.26, "volume": 0.13, "wobble": 10.0, "noise": 0.0, "waveform": "sine"},
		{"duration": 0.060, "volume": 0.0},
		{"frequency": 1320.0, "end_frequency": 1980.0, "duration": 0.20, "volume": 0.11, "wobble": 12.0, "noise": 0.0, "waveform": "sine"}
	])


static func make_click() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 340.0, "duration": 0.030, "volume": 0.08, "wobble": 18.0, "noise": 0.28, "waveform": "triangle"}
	])


static func make_background_loop() -> AudioStreamWAV:
	var duration := 12.0
	var sample_count := int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	var notes: Array[float] = [261.63, 329.63, 392.0, 493.88, 440.0, 392.0, 329.63, 293.66]

	for i in range(sample_count):
		var t := float(i) / float(MIX_RATE)
		var progress := float(i) / float(sample_count)
		var note_index := int(floor(t * 1.5)) % notes.size()
		var note: float = notes[note_index]
		var pad := sin(TAU * note * t) * 0.045
		pad += sin(TAU * note * 0.5 * t) * 0.035
		pad += sin(TAU * notes[(note_index + 2) % notes.size()] * 0.25 * t) * 0.025
		var breeze := randf_range(-1.0, 1.0) * 0.010
		var fade := minf(smoothstep(0.0, 0.08, progress), 1.0 - smoothstep(0.92, 1.0, progress))
		_append_sample(bytes, (pad + breeze) * fade)

	var stream := _make_stream(bytes)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


static func make_phrase(segments: Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()

	for segment in segments:
		var duration: float = segment.get("duration", 0.1)
		var sample_count := maxi(1, int(MIX_RATE * duration))
		var frequency: float = segment.get("frequency", 440.0)
		var end_frequency: float = segment.get("end_frequency", frequency)
		var volume: float = segment.get("volume", 0.26)
		var wobble: float = segment.get("wobble", 0.0)
		var noise: float = segment.get("noise", 0.0)
		var waveform: String = segment.get("waveform", "sine")

		for i in range(sample_count):
			var t := float(i) / float(MIX_RATE)
			var progress := float(i) / float(sample_count)
			var envelope := sin(progress * PI)
			var frequency_now := lerpf(frequency, end_frequency, progress)
			var phase := TAU * (frequency_now + sin(t * TAU * 8.0) * wobble) * t
			var wave := _wave(phase, waveform)
			if noise > 0.0:
				wave = lerpf(wave, randf_range(-1.0, 1.0), noise)
			_append_sample(bytes, wave * volume * envelope)

	return _make_stream(bytes)


static func _wave(phase: float, waveform: String) -> float:
	match waveform:
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"triangle":
			return asin(sin(phase)) * 2.0 / PI
		"noise":
			return randf_range(-1.0, 1.0)
		_:
			return sin(phase)


static func _append_sample(bytes: PackedByteArray, sample_value: float) -> void:
	var sample := int(clampf(sample_value, -1.0, 1.0) * INT16_SCALE)
	bytes.append(sample & 0xff)
	bytes.append((sample >> 8) & 0xff)


static func _make_stream(bytes: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
