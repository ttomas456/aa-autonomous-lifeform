extends RefCounted
class_name ProceduralSound

const MIX_RATE := 22050


static func make_tone(frequency: float, duration: float, volume := 0.32, wobble := 0.0) -> AudioStreamWAV:
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
		{"frequency": 210.0 * personality_pitch, "end_frequency": 150.0 * personality_pitch, "duration": 0.075, "volume": 0.56, "wobble": 36.0, "noise": 0.34},
		{"duration": 0.035, "volume": 0.0},
		{"frequency": 260.0 * personality_pitch, "end_frequency": 175.0 * personality_pitch, "duration": 0.095, "volume": 0.48, "wobble": 42.0, "noise": 0.28}
	])


static func make_happy_yip(personality_pitch := 1.0) -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 640.0 * personality_pitch, "end_frequency": 920.0 * personality_pitch, "duration": 0.075, "volume": 0.30, "wobble": 110.0, "noise": 0.06},
		{"duration": 0.025, "volume": 0.0},
		{"frequency": 760.0 * personality_pitch, "end_frequency": 1020.0 * personality_pitch, "duration": 0.065, "volume": 0.26, "wobble": 130.0, "noise": 0.04}
	])


static func make_whine(personality_pitch := 1.0) -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 420.0 * personality_pitch, "end_frequency": 560.0 * personality_pitch, "duration": 0.22, "volume": 0.20, "wobble": 95.0, "noise": 0.03}
	])


static func make_chew() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 140.0, "duration": 0.055, "volume": 0.26, "wobble": 20.0, "noise": 0.52},
		{"duration": 0.035, "volume": 0.0},
		{"frequency": 115.0, "duration": 0.050, "volume": 0.24, "wobble": 18.0, "noise": 0.58},
		{"duration": 0.030, "volume": 0.0},
		{"frequency": 155.0, "duration": 0.045, "volume": 0.20, "wobble": 24.0, "noise": 0.48}
	])


static func make_toy_squeak() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 980.0, "end_frequency": 1460.0, "duration": 0.085, "volume": 0.30, "wobble": 190.0, "noise": 0.02},
		{"frequency": 1320.0, "end_frequency": 820.0, "duration": 0.10, "volume": 0.24, "wobble": 160.0, "noise": 0.03}
	])


static func make_snore() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 86.0, "end_frequency": 118.0, "duration": 0.34, "volume": 0.16, "wobble": 10.0, "noise": 0.18},
		{"duration": 0.08, "volume": 0.0},
		{"frequency": 112.0, "end_frequency": 74.0, "duration": 0.26, "volume": 0.13, "wobble": 8.0, "noise": 0.20}
	])


static func make_whistle() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 940.0, "end_frequency": 1540.0, "duration": 0.22, "volume": 0.28, "wobble": 18.0, "noise": 0.0},
		{"duration": 0.045, "volume": 0.0},
		{"frequency": 1260.0, "end_frequency": 1780.0, "duration": 0.18, "volume": 0.24, "wobble": 24.0, "noise": 0.0}
	])


static func make_click() -> AudioStreamWAV:
	return make_phrase([
		{"frequency": 380.0, "duration": 0.035, "volume": 0.20, "wobble": 24.0, "noise": 0.22}
	])


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

		for i in range(sample_count):
			var t := float(i) / float(MIX_RATE)
			var progress := float(i) / float(sample_count)
			var envelope := sin(progress * PI)
			var frequency_now := lerpf(frequency, end_frequency, progress)
			var wave := sin(TAU * (frequency_now + sin(t * TAU * 8.0) * wobble) * t)
			if noise > 0.0:
				wave = lerpf(wave, randf_range(-1.0, 1.0), noise)
			var sample := int(clampf(128.0 + wave * 127.0 * volume * envelope, 0.0, 255.0))
			bytes.append(sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
