extends RefCounted
class_name ProceduralSound

const MIX_RATE := 22050


static func make_tone(frequency: float, duration: float, volume := 0.32, wobble := 0.0) -> AudioStreamWAV:
	var sample_count := maxi(1, int(MIX_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(sample_count)

	for i in range(sample_count):
		var t := float(i) / float(MIX_RATE)
		var progress := float(i) / float(sample_count)
		var envelope := sin(progress * PI)
		var wave := sin(TAU * (frequency + sin(t * TAU * 7.0) * wobble) * t)
		var sample := int(clampf(128.0 + wave * 127.0 * volume * envelope, 0.0, 255.0))
		bytes[i] = sample

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
