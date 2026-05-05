extends CharacterBody2D
class_name DogAgent

const DogNeedsScript := preload("res://scripts/dog_needs.gd")
const DogMemoryScript := preload("res://scripts/dog_memory.gd")
const ProceduralSoundScript := preload("res://scripts/procedural_sound.gd")

enum DogState {
	IDLE,
	WANDER,
	FOLLOW_PLAYER,
	SEEK_FOOD,
	PLAY,
	SLEEP
}

const STATE_NAMES := {
	DogState.IDLE: "Idle",
	DogState.WANDER: "Wander",
	DogState.FOLLOW_PLAYER: "Follow",
	DogState.SEEK_FOOD: "Seek Food",
	DogState.PLAY: "Play",
	DogState.SLEEP: "Sleep"
}

@export var dog_name := "Dog"
@export var coat_color := Color("c98c57")
@export var accent_color := Color("f4d4a5")
@export var move_speed := 150.0
@export var steering_force := 700.0
@export var hunger_rate := 2.3
@export var energy_drain := 1.8
@export var happiness_drift := 1.0
@export_range(0.0, 1.0, 0.01) var curiosity := 0.5
@export_range(0.0, 1.0, 0.01) var sociability := 0.5
@export_range(0.0, 1.0, 0.01) var playfulness := 0.5
@export_range(0.0, 1.0, 0.01) var rest_bias := 0.5

@onready var name_label: Label = $NameLabel
@onready var thought_label: Label = $ThoughtLabel
@onready var status_label: Label = $StatusLabel

var world: Node = null
var needs := DogNeedsScript.new()
var memory := DogMemoryScript.new()
var state := DogState.IDLE
var decision_timer := 0.0
var wander_target := Vector2.ZERO
var target_item: Node2D = null
var target_pack_mate: Node2D = null
var facing := Vector2.RIGHT
var tail_time := 0.0
var bed_position := Vector2.ZERO
var favorite_spots: Array = []
var thought := "Settling in"
var wander_bias := 0.65
var emotion_motes: Array[Dictionary] = []
var sound_player: AudioStreamPlayer2D = null
var voice_pitch := 1.0
var whistle_response_timer := 0.0


func configure(profile: Dictionary) -> void:
	dog_name = profile.get("dog_name", dog_name)
	coat_color = profile.get("coat_color", coat_color)
	accent_color = profile.get("accent_color", accent_color)
	move_speed = profile.get("move_speed", move_speed)
	curiosity = profile.get("curiosity", curiosity)
	sociability = profile.get("sociability", sociability)
	playfulness = profile.get("playfulness", playfulness)
	rest_bias = profile.get("rest_bias", rest_bias)
	wander_bias = profile.get("wander_bias", wander_bias)
	bed_position = profile.get("bed_position", bed_position)
	favorite_spots = profile.get("favorite_spots", favorite_spots)
	voice_pitch = profile.get("voice_pitch", voice_pitch)
	needs.configure(profile)


func _ready() -> void:
	world = get_tree().get_first_node_in_group("world")
	name_label.text = dog_name
	_setup_sound()
	needs.randomize_start()
	choose_state(true)


func _physics_process(delta: float) -> void:
	if world == null:
		world = get_tree().get_first_node_in_group("world")
		if world == null:
			return

	_update_needs(delta)
	memory.tick(delta)
	_update_emotion_motes(delta)
	_update_whistle_response(delta)
	decision_timer -= delta

	if _needs_urgent_transition() or decision_timer <= 0.0:
		choose_state()

	var desired_velocity := _get_desired_velocity()
	velocity = velocity.move_toward(desired_velocity, steering_force * delta)
	move_and_slide()
	global_position = world.clamp_to_world(global_position)

	if velocity.length() > 4.0:
		facing = velocity.normalized()

	tail_time += delta * (2.0 + playfulness * 1.5 + needs.happiness / 90.0)
	_update_labels()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0.0, 18.0), 18.0, Color(0, 0, 0, 0.12))
	var tail_length := 18.0 + needs.happiness * 0.08
	var tail_swing := sin(tail_time * 6.0) * deg_to_rad(16.0 + playfulness * 26.0)
	var tail_direction := (-facing).rotated(tail_swing)
	var head_center := facing * 18.0
	var ear_left := head_center + facing.rotated(-1.9) * 12.0
	var ear_right := head_center + facing.rotated(1.9) * 12.0
	var nose := head_center + facing * 12.0
	var eye_offset := facing.rotated(PI / 2.0) * 3.0

	draw_line(Vector2.ZERO, tail_direction * tail_length, accent_color.darkened(0.25), 7.0, true)
	draw_circle(Vector2.ZERO, 20.0, coat_color)
	draw_circle(head_center, 14.0, coat_color.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([head_center, ear_left, head_center + facing.rotated(-1.2) * 10.0]), accent_color)
	draw_colored_polygon(PackedVector2Array([head_center, ear_right, head_center + facing.rotated(1.2) * 10.0]), accent_color)
	draw_circle(nose, 3.0, Color("2f2a24"))
	draw_circle(head_center + eye_offset + facing * 2.0, 2.0, Color("2f2a24"))
	draw_circle(head_center - eye_offset + facing * 2.0, 2.0, Color("2f2a24"))
	if state == DogState.SLEEP:
		draw_arc(Vector2(-24.0, -24.0), 12.0, deg_to_rad(190.0), deg_to_rad(350.0), 16, accent_color.darkened(0.2), 3.0)
	if state == DogState.FOLLOW_PLAYER:
		draw_circle(Vector2(28.0, -28.0), 4.0, Color("de6b6b"))
	if state == DogState.PLAY:
		draw_circle(Vector2(26.0, -26.0), 4.0, Color("f6d365"))
	if memory.excitement > 20.0:
		draw_arc(Vector2.ZERO, 30.0, -0.8, 0.8, 12, accent_color.lightened(0.35), 3.0)
	_draw_emotion_motes()


func _update_needs(delta: float) -> void:
	needs.tick(delta, velocity.length(), move_speed, state == DogState.SLEEP, state == DogState.PLAY)


func choose_state(force := false) -> void:
	target_item = null
	target_pack_mate = null

	var next_state = state
	var food_target = world.get_nearest_item("food", global_position)
	var toy_target = world.get_nearest_item("toy", global_position)
	var player_distance = global_position.distance_to(world.get_player_position())
	var follow_radius := lerpf(150.0, 250.0, sociability) + memory.social_pull(sociability)
	var sleep_threshold = needs.sleep_threshold()
	var mate_distance := INF

	if target_pack_mate == null:
		target_pack_mate = world.get_pack_mate(self)
	if target_pack_mate != null:
		mate_distance = global_position.distance_to(target_pack_mate.global_position)

	if needs.energy <= sleep_threshold:
		next_state = DogState.SLEEP
	elif needs.hunger >= 58.0 and food_target != null:
		next_state = DogState.SEEK_FOOD
		target_item = food_target
	elif toy_target != null and (playfulness * 100.0) > randf_range(18.0, 100.0):
		next_state = DogState.PLAY
		target_item = toy_target
	elif player_distance <= follow_radius:
		next_state = DogState.FOLLOW_PLAYER
	elif playfulness > 0.55 and needs.happiness < 64.0:
		if target_pack_mate != null:
			next_state = DogState.PLAY
	elif mate_distance < 120.0 and sociability > 0.45 and randf() < sociability:
		next_state = DogState.IDLE
	elif curiosity * wander_bias > randf():
		next_state = DogState.WANDER
		_pick_new_wander_target()
	else:
		next_state = DogState.IDLE

	if next_state != state or force:
		state = next_state
		if state == DogState.WANDER:
			_pick_new_wander_target()
		_update_thought()
		_play_state_sound()

	decision_timer = randf_range(1.0, 2.6)


func _get_desired_velocity() -> Vector2:
	match state:
		DogState.IDLE:
			return Vector2.ZERO
		DogState.WANDER:
			if global_position.distance_to(wander_target) < 18.0:
				_pick_new_wander_target()
			return _seek(wander_target, 0.7)
		DogState.FOLLOW_PLAYER:
			return _arrive(world.get_player_position(), 54.0, 0.95)
		DogState.SEEK_FOOD:
			if not is_instance_valid(target_item):
				target_item = world.get_nearest_item("food", global_position)
				if target_item == null:
					choose_state(true)
					return Vector2.ZERO
			if global_position.distance_to(target_item.global_position) < 22.0:
				world.consume_item(target_item)
				target_item = null
				needs.eat()
				_emit_emotion_motes(Color("f6d77b"), 6, "crumb")
				_play_sound(ProceduralSoundScript.make_chew())
				choose_state(true)
				return Vector2.ZERO
			return _arrive(target_item.global_position, 22.0, 1.0)
		DogState.PLAY:
			if is_instance_valid(target_item):
				if global_position.distance_to(target_item.global_position) < 26.0:
					world.register_play(target_item)
					needs.play()
					_emit_emotion_motes(Color("f6d365"), 8, "spark")
					_play_sound(ProceduralSoundScript.make_toy_squeak())
					_pick_new_wander_target()
					decision_timer = 0.2
					return _seek(wander_target, 0.6)
				return _arrive(target_item.global_position, 28.0, 1.15)

			if is_instance_valid(target_pack_mate):
				if global_position.distance_to(target_pack_mate.global_position) < 30.0:
					needs.play(10.0, 2.0)
					decision_timer = 0.1
					return Vector2.ZERO
				return _arrive(target_pack_mate.global_position, 30.0, 1.0)

			target_pack_mate = world.get_pack_mate(self)
			if target_pack_mate != null:
				return _arrive(target_pack_mate.global_position, 30.0, 0.9)
			choose_state(true)
			return Vector2.ZERO
		DogState.SLEEP:
			if global_position.distance_to(bed_position) > 14.0:
				return _arrive(bed_position, 18.0, 0.65)
			return Vector2.ZERO

	return Vector2.ZERO


func _pick_new_wander_target() -> void:
	if not favorite_spots.is_empty() and randf() < wander_bias:
		var anchor: Vector2 = favorite_spots[randi_range(0, favorite_spots.size() - 1)]
		wander_target = world.clamp_to_world(anchor + Vector2(randf_range(-80.0, 80.0), randf_range(-70.0, 70.0)))
		return

	var bounds = world.get_world_bounds()
	wander_target = Vector2(
		randf_range(bounds.position.x, bounds.end.x),
		randf_range(bounds.position.y, bounds.end.y)
	)


func _seek(target: Vector2, speed_scale: float) -> Vector2:
	var direction := target - global_position
	if direction.length() < 1.0:
		return Vector2.ZERO
	return direction.normalized() * move_speed * speed_scale


func _arrive(target: Vector2, slow_radius: float, speed_scale: float) -> Vector2:
	var direction := target - global_position
	var distance := direction.length()
	if distance < 1.0:
		return Vector2.ZERO
	var speed_multiplier: float = clampf(distance / maxf(slow_radius, 1.0), 0.0, 1.0)
	return direction.normalized() * move_speed * speed_scale * speed_multiplier


func _needs_urgent_transition() -> bool:
	if state == DogState.SLEEP and needs.energy >= 82.0:
		return true
	if state != DogState.SLEEP and needs.energy <= needs.sleep_threshold():
		return true
	if state != DogState.SEEK_FOOD and needs.hunger >= 72.0 and world.get_nearest_item("food", global_position) != null:
		return true
	return false


func _update_labels() -> void:
	name_label.text = dog_name
	thought_label.text = thought
	status_label.text = "%s | H %.0f E %.0f M %.0f" % [
		STATE_NAMES[state],
		needs.hunger,
		needs.energy,
		needs.happiness
	]


func _update_thought() -> void:
	match state:
		DogState.IDLE:
			thought = "Watching the yard"
		DogState.WANDER:
			thought = "Sniffing around"
		DogState.FOLLOW_PLAYER:
			thought = "Sticking close"
		DogState.SEEK_FOOD:
			thought = "Looking for food"
		DogState.PLAY:
			thought = "Ready to play"
		DogState.SLEEP:
			thought = "Heading for a nap"
			_emit_emotion_motes(Color("8795c9"), 3, "sleep")


func get_snapshot() -> Dictionary:
	return {
		"dog_name": dog_name,
		"hunger": needs.hunger,
		"energy": needs.energy,
		"happiness": needs.happiness,
		"state": STATE_NAMES[state],
		"thought": thought,
		"trust": memory.trust,
		"last_event": memory.last_event
	}


func react_to_pet() -> void:
	needs.comfort(14.0 + sociability * 8.0)
	memory.remember("Petted by player", 8.0 + sociability * 6.0, 55.0)
	_emit_emotion_motes(Color("de6b6b"), 9, "heart")
	_play_sound(ProceduralSoundScript.make_happy_yip(voice_pitch))
	state = DogState.FOLLOW_PLAYER
	thought = "That felt kind"
	decision_timer = 1.2


func hear_whistle(source_position: Vector2) -> void:
	wander_target = source_position
	memory.remember("Heard whistle", 2.0, 35.0)
	_emit_emotion_motes(Color("e8f4ff"), 4, "ping")
	whistle_response_timer = randf_range(0.32, 0.56)
	state = DogState.FOLLOW_PLAYER
	thought = "Coming!"
	decision_timer = 1.4


func draw_debug_gizmo() -> void:
	var target := global_position
	match state:
		DogState.WANDER:
			target = wander_target
		DogState.FOLLOW_PLAYER:
			target = world.get_player_position()
		DogState.SEEK_FOOD, DogState.PLAY:
			if is_instance_valid(target_item):
				target = target_item.global_position
		DogState.SLEEP:
			target = bed_position
	world.draw_line(global_position, target, Color("2b7a78", 0.8), 2.0, true)
	world.draw_circle(target, 8.0, Color("2b7a78", 0.35))


func _emit_emotion_motes(color: Color, count: int, mote_type: String) -> void:
	for i in range(count):
		emotion_motes.append({
			"position": Vector2(randf_range(-18.0, 18.0), randf_range(-38.0, -14.0)),
			"velocity": Vector2(randf_range(-16.0, 16.0), randf_range(-34.0, -18.0)),
			"life": randf_range(0.65, 1.1),
			"max_life": 1.1,
			"color": color,
			"type": mote_type,
			"size": randf_range(3.0, 6.0)
		})


func _update_emotion_motes(delta: float) -> void:
	for i in range(emotion_motes.size() - 1, -1, -1):
		emotion_motes[i]["life"] -= delta
		emotion_motes[i]["position"] += emotion_motes[i]["velocity"] * delta
		emotion_motes[i]["velocity"] *= 0.985
		if emotion_motes[i]["life"] <= 0.0:
			emotion_motes.remove_at(i)


func _draw_emotion_motes() -> void:
	for mote in emotion_motes:
		var alpha: float = clampf(mote["life"] / mote["max_life"], 0.0, 1.0)
		var color: Color = mote["color"] * Color(1.0, 1.0, 1.0, alpha)
		var position: Vector2 = mote["position"]
		var size: float = mote["size"]
		match mote["type"]:
			"heart":
				draw_circle(position + Vector2(-size * 0.35, 0.0), size * 0.45, color)
				draw_circle(position + Vector2(size * 0.35, 0.0), size * 0.45, color)
				draw_colored_polygon(PackedVector2Array([
					position + Vector2(-size * 0.85, size * 0.15),
					position + Vector2(size * 0.85, size * 0.15),
					position + Vector2(0.0, size * 1.05)
				]), color)
			"sleep":
				draw_string(ThemeDB.fallback_font, position, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
			_:
				draw_circle(position, size, color)


func _setup_sound() -> void:
	sound_player = AudioStreamPlayer2D.new()
	sound_player.name = "Voice"
	sound_player.max_distance = 520.0
	sound_player.volume_db = -19.0
	add_child(sound_player)


func _play_tone(frequency: float, duration: float, volume: float, wobble: float) -> void:
	_play_sound(ProceduralSoundScript.make_tone(frequency, duration, volume, wobble))


func _play_sound(stream: AudioStreamWAV) -> void:
	if sound_player == null:
		return
	sound_player.stream = stream
	sound_player.play()


func _play_state_sound() -> void:
	match state:
		DogState.FOLLOW_PLAYER:
			if memory.excitement > 25.0 or randf() < sociability:
				_play_sound(ProceduralSoundScript.make_bark(voice_pitch))
		DogState.SEEK_FOOD:
			_play_sound(ProceduralSoundScript.make_whine(voice_pitch))
		DogState.PLAY:
			_play_sound(ProceduralSoundScript.make_happy_yip(voice_pitch))
		DogState.SLEEP:
			_play_sound(ProceduralSoundScript.make_snore())


func _update_whistle_response(delta: float) -> void:
	if whistle_response_timer <= 0.0:
		return
	whistle_response_timer -= delta
	if whistle_response_timer <= 0.0:
		_play_sound(ProceduralSoundScript.make_bark(voice_pitch))
