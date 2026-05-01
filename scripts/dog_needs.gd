extends RefCounted
class_name DogNeeds

var hunger := 28.0
var energy := 88.0
var happiness := 76.0
var hunger_rate := 2.3
var energy_drain := 1.8
var happiness_drift := 1.0
var rest_bias := 0.5
var sociability := 0.5


func configure(profile: Dictionary) -> void:
	hunger_rate = profile.get("hunger_rate", hunger_rate)
	energy_drain = profile.get("energy_drain", energy_drain)
	happiness_drift = profile.get("happiness_drift", happiness_drift)
	rest_bias = profile.get("rest_bias", rest_bias)
	sociability = profile.get("sociability", sociability)


func randomize_start() -> void:
	hunger = randf_range(18.0, 36.0)
	energy = randf_range(68.0, 92.0)
	happiness = randf_range(58.0, 84.0)


func tick(delta: float, velocity_length: float, max_speed: float, is_sleeping: bool, is_playing: bool) -> void:
	var activity_scale := 1.0 + velocity_length / maxf(max_speed, 1.0)
	hunger = clampf(hunger + hunger_rate * delta, 0.0, 100.0)
	energy = clampf(energy - energy_drain * delta * activity_scale, 0.0, 100.0)
	happiness = clampf(happiness - happiness_drift * delta + 0.35 * delta * sociability, 0.0, 100.0)

	if is_sleeping:
		energy = clampf(energy + (18.0 + rest_bias * 8.0) * delta, 0.0, 100.0)
		happiness = clampf(happiness + 4.0 * delta, 0.0, 100.0)
	elif is_playing:
		happiness = clampf(happiness + 6.5 * delta, 0.0, 100.0)
		energy = clampf(energy - 2.2 * delta, 0.0, 100.0)


func eat(amount := 46.0) -> void:
	hunger = clampf(hunger - amount, 0.0, 100.0)
	happiness = clampf(happiness + 10.0, 0.0, 100.0)


func play(happiness_gain := 14.0, energy_cost := 8.0) -> void:
	happiness = clampf(happiness + happiness_gain, 0.0, 100.0)
	energy = clampf(energy - energy_cost, 0.0, 100.0)


func comfort(amount := 12.0) -> void:
	happiness = clampf(happiness + amount, 0.0, 100.0)
	energy = clampf(energy + amount * 0.25, 0.0, 100.0)


func sleep_threshold() -> float:
	return lerpf(38.0, 54.0, rest_bias)
