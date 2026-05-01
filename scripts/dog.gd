extends CharacterBody2D
class_name DogAgent

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
var hunger := 28.0
var energy := 88.0
var happiness := 76.0
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


func configure(profile: Dictionary) -> void:
	dog_name = profile.get("dog_name", dog_name)
	coat_color = profile.get("coat_color", coat_color)
	accent_color = profile.get("accent_color", accent_color)
	move_speed = profile.get("move_speed", move_speed)
	hunger_rate = profile.get("hunger_rate", hunger_rate)
	energy_drain = profile.get("energy_drain", energy_drain)
	curiosity = profile.get("curiosity", curiosity)
	sociability = profile.get("sociability", sociability)
	playfulness = profile.get("playfulness", playfulness)
	rest_bias = profile.get("rest_bias", rest_bias)
	wander_bias = profile.get("wander_bias", wander_bias)
	bed_position = profile.get("bed_position", bed_position)
	favorite_spots = profile.get("favorite_spots", favorite_spots)


func _ready() -> void:
	world = get_tree().get_first_node_in_group("world")
	name_label.text = dog_name
	hunger = randf_range(18.0, 36.0)
	energy = randf_range(68.0, 92.0)
	happiness = randf_range(58.0, 84.0)
	choose_state(true)


func _physics_process(delta: float) -> void:
	if world == null:
		world = get_tree().get_first_node_in_group("world")
		if world == null:
			return

	_update_needs(delta)
	decision_timer -= delta

	if _needs_urgent_transition() or decision_timer <= 0.0:
		choose_state()

	var desired_velocity := _get_desired_velocity()
	velocity = velocity.move_toward(desired_velocity, steering_force * delta)
	move_and_slide()
	global_position = world.clamp_to_world(global_position)

	if velocity.length() > 4.0:
		facing = velocity.normalized()

	tail_time += delta * (2.0 + playfulness * 1.5 + happiness / 90.0)
	_update_labels()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0.0, 18.0), 18.0, Color(0, 0, 0, 0.12))
	var tail_length := 18.0 + happiness * 0.08
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


func _update_needs(delta: float) -> void:
	var activity_scale = 1.0 + velocity.length() / max(move_speed, 1.0)
	hunger = clampf(hunger + hunger_rate * delta, 0.0, 100.0)
	energy = clampf(energy - energy_drain * delta * activity_scale, 0.0, 100.0)
	happiness = clampf(happiness - happiness_drift * delta + 0.35 * delta * sociability, 0.0, 100.0)

	if state == DogState.SLEEP:
		energy = clampf(energy + (18.0 + rest_bias * 8.0) * delta, 0.0, 100.0)
		happiness = clampf(happiness + 4.0 * delta, 0.0, 100.0)
	elif state == DogState.PLAY:
		happiness = clampf(happiness + 6.5 * delta, 0.0, 100.0)
		energy = clampf(energy - 2.2 * delta, 0.0, 100.0)


func choose_state(force := false) -> void:
	target_item = null
	target_pack_mate = null

	var next_state = state
	var food_target = world.get_nearest_item("food", global_position)
	var toy_target = world.get_nearest_item("toy", global_position)
	var player_distance = global_position.distance_to(world.get_player_position())
	var sleep_threshold = lerpf(38.0, 54.0, rest_bias)
	var mate_distance := INF

	if target_pack_mate == null:
		target_pack_mate = world.get_pack_mate(self)
	if target_pack_mate != null:
		mate_distance = global_position.distance_to(target_pack_mate.global_position)

	if energy <= sleep_threshold:
		next_state = DogState.SLEEP
	elif hunger >= 58.0 and food_target != null:
		next_state = DogState.SEEK_FOOD
		target_item = food_target
	elif toy_target != null and (playfulness * 100.0) > randf_range(18.0, 100.0):
		next_state = DogState.PLAY
		target_item = toy_target
	elif player_distance <= lerpf(150.0, 250.0, sociability):
		next_state = DogState.FOLLOW_PLAYER
	elif playfulness > 0.55 and happiness < 64.0:
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
				hunger = clampf(hunger - 46.0, 0.0, 100.0)
				happiness = clampf(happiness + 10.0, 0.0, 100.0)
				choose_state(true)
				return Vector2.ZERO
			return _arrive(target_item.global_position, 22.0, 1.0)
		DogState.PLAY:
			if is_instance_valid(target_item):
				if global_position.distance_to(target_item.global_position) < 26.0:
					world.register_play(target_item)
					happiness = clampf(happiness + 14.0, 0.0, 100.0)
					energy = clampf(energy - 8.0, 0.0, 100.0)
					_pick_new_wander_target()
					decision_timer = 0.2
					return _seek(wander_target, 0.6)
				return _arrive(target_item.global_position, 28.0, 1.15)

			if is_instance_valid(target_pack_mate):
				if global_position.distance_to(target_pack_mate.global_position) < 30.0:
					happiness = clampf(happiness + 10.0, 0.0, 100.0)
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
	if state == DogState.SLEEP and energy >= 82.0:
		return true
	if state != DogState.SLEEP and energy <= lerpf(38.0, 54.0, rest_bias):
		return true
	if state != DogState.SEEK_FOOD and hunger >= 72.0 and world.get_nearest_item("food", global_position) != null:
		return true
	return false


func _update_labels() -> void:
	name_label.text = dog_name
	thought_label.text = thought
	status_label.text = "%s | H %.0f E %.0f M %.0f" % [
		STATE_NAMES[state],
		hunger,
		energy,
		happiness
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


func get_snapshot() -> Dictionary:
	return {
		"dog_name": dog_name,
		"hunger": hunger,
		"energy": energy,
		"happiness": happiness,
		"state": STATE_NAMES[state],
		"thought": thought
	}
