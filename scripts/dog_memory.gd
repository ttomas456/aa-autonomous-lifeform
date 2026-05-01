extends RefCounted
class_name DogMemory

const MAX_EVENTS := 6

var trust := 38.0
var excitement := 0.0
var last_event := "New day"
var recent_events: Array[String] = []


func remember(event_text: String, trust_delta := 0.0, excitement_delta := 0.0) -> void:
	last_event = event_text
	trust = clampf(trust + trust_delta, 0.0, 100.0)
	excitement = clampf(excitement + excitement_delta, 0.0, 100.0)
	recent_events.push_front(event_text)
	if recent_events.size() > MAX_EVENTS:
		recent_events.pop_back()


func tick(delta: float) -> void:
	excitement = move_toward(excitement, 0.0, delta * 8.0)


func social_pull(sociability: float) -> float:
	return lerpf(0.0, 70.0, trust / 100.0) * sociability
