extends Node2D

const DOG_SCENE := preload("res://scenes/dog.tscn")
const ITEM_SCENE := preload("res://scenes/world_item.tscn")
const WORLD_SIZE := Vector2(1280.0, 720.0)
const PLAY_AREA := Rect2(Vector2(48.0, 96.0), Vector2(1184.0, 576.0))
const PLAYER_SPEED := 320.0
const FOOD_LIMIT := 5
const TOY_LIMIT := 3
const BED_POSITIONS := {
	"Buster": Vector2(236.0, 156.0),
	"Cleo": Vector2(1044.0, 156.0)
}
const ENRICHMENT_SPOTS := {
	"Buster": [
		Vector2(318.0, 284.0),
		Vector2(646.0, 534.0),
		Vector2(952.0, 408.0)
	],
	"Cleo": [
		Vector2(986.0, 246.0),
		Vector2(760.0, 468.0),
		Vector2(332.0, 392.0)
	]
}

@onready var player: Marker2D = $Player
@onready var dogs_container: Node2D = $Dogs
@onready var food_items: Node2D = $FoodItems
@onready var toy_items: Node2D = $ToyItems
@onready var camera: Camera2D = $Camera2D
@onready var hud_label: Label = $Hud/Instructions
@onready var dog_status_label: Label = $Hud/DogStatus
@onready var hint_label: Label = $Hud/HintLabel

var day_time := 0.0
var camera_shake := 0.0
var debug_gizmos := false


func _ready() -> void:
	add_to_group("world")
	randomize()
	_spawn_dogs()
	_refresh_hud()


func _process(delta: float) -> void:
	day_time += delta
	_update_camera(delta)
	_update_player(delta)
	_refresh_hud()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var click_position := clamp_to_world(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_spawn_item(food_items, "food", click_position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_spawn_item(toy_items, "toy", click_position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_pet_nearest_dog()
		elif event.keycode == KEY_Q:
			_whistle_pack()
		elif event.keycode == KEY_G:
			debug_gizmos = not debug_gizmos


func _draw() -> void:
	var warmth := 0.5 + sin(day_time * 0.16) * 0.5
	var sky_color := Color("dce7f7").lerp(Color("f4dfbb"), warmth * 0.22)
	var grass_color := Color("cadfad").lerp(Color("b9d28d"), warmth * 0.18)
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("e7efe9"), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(WORLD_SIZE.x, 140.0)), sky_color, true)
	draw_circle(Vector2(1120.0, 84.0), 42.0, Color("f8d77a"))
	_draw_clouds()
	draw_rect(PLAY_AREA, grass_color, true)
	_draw_grass_texture()
	draw_rect(PLAY_AREA.grow(16.0), Color("7f9264"), false, 7.0)
	_draw_fence()
	_draw_enrichment_spots()
	_draw_bed("Buster", BED_POSITIONS["Buster"], Color("c98c57"), Color("f1d3ae"))
	_draw_bed("Cleo", BED_POSITIONS["Cleo"], Color("8e715a"), Color("dcc0a1"))
	_draw_zone(Vector2(130.0, 618.0), Vector2(170.0, 58.0), Color("d96c5f"), "Food")
	_draw_zone(Vector2(980.0, 618.0), Vector2(170.0, 58.0), Color("5aa6d6"), "Toy Box")
	_draw_player()
	_draw_hud_backplates()
	if debug_gizmos:
		_draw_world_gizmos()


func get_player_position() -> Vector2:
	return player.position


func get_nearest_item(item_type: String, origin: Vector2) -> Node2D:
	var closest_item: Node2D = null
	var best_distance := INF
	var container := _get_item_container(item_type)
	for child in container.get_children():
		var item := child as Node2D
		var distance_to_item := origin.distance_squared_to(item.global_position)
		if distance_to_item < best_distance:
			best_distance = distance_to_item
			closest_item = item
	return closest_item


func consume_item(item: Node2D) -> void:
	if is_instance_valid(item):
		item.queue_free()


func register_play(item: Node2D) -> void:
	if is_instance_valid(item) and item.has_method("bump"):
		item.bump()


func get_pack_mate(source: Node2D) -> Node2D:
	var nearest_mate: Node2D = null
	var best_distance := INF
	for child in dogs_container.get_children():
		if child == source:
			continue
		var mate := child as Node2D
		var distance_to_mate := source.global_position.distance_squared_to(mate.global_position)
		if distance_to_mate < best_distance:
			best_distance = distance_to_mate
			nearest_mate = mate
	return nearest_mate


func get_world_bounds() -> Rect2:
	return PLAY_AREA


func get_bed_position(dog_name: String) -> Vector2:
	return BED_POSITIONS.get(dog_name, PLAY_AREA.get_center())


func get_interest_points(dog_name: String) -> Array:
	return ENRICHMENT_SPOTS.get(dog_name, [])


func clamp_to_world(point: Vector2) -> Vector2:
	var bounds := get_world_bounds()
	return Vector2(
		clampf(point.x, bounds.position.x, bounds.end.x),
		clampf(point.y, bounds.position.y, bounds.end.y)
	)


func _spawn_dogs() -> void:
	var profiles := [
		{
			"dog_name": "Buster",
			"coat_color": Color("c98c57"),
			"accent_color": Color("f4d4a5"),
			"move_speed": 165.0,
			"curiosity": 0.62,
			"sociability": 0.92,
			"playfulness": 0.95,
			"rest_bias": 0.35,
			"wander_bias": 0.52,
			"hunger_rate": 2.2,
			"energy_drain": 1.95,
			"spawn_position": Vector2(420.0, 360.0)
		},
		{
			"dog_name": "Cleo",
			"coat_color": Color("8e715a"),
			"accent_color": Color("d8c2a3"),
			"move_speed": 138.0,
			"curiosity": 0.88,
			"sociability": 0.48,
			"playfulness": 0.52,
			"rest_bias": 0.62,
			"wander_bias": 0.86,
			"hunger_rate": 1.95,
			"energy_drain": 1.55,
			"spawn_position": Vector2(820.0, 410.0)
		}
	]

	for profile in profiles:
		var dog = DOG_SCENE.instantiate()
		profile["bed_position"] = BED_POSITIONS[profile["dog_name"]]
		profile["favorite_spots"] = ENRICHMENT_SPOTS[profile["dog_name"]]
		dog.configure(profile)
		dog.position = profile["spawn_position"]
		dogs_container.add_child(dog)


func _spawn_item(container: Node2D, item_type: String, drop_position: Vector2) -> void:
	var limit = FOOD_LIMIT if item_type == "food" else TOY_LIMIT
	if container.get_child_count() >= limit:
		container.get_child(0).queue_free()

	var item = ITEM_SCENE.instantiate()
	item.configure(item_type, drop_position)
	container.add_child(item)
	_bump_camera(2.5)


func _update_player(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction.y += 1.0

	if direction != Vector2.ZERO:
		player.position = clamp_to_world(player.position + direction.normalized() * PLAYER_SPEED * delta)


func _refresh_hud() -> void:
	hud_label.text = "WASD/Arrows move. Left click food. Right click toy.\nE pets. Q whistles. G toggles gizmos.\nFood: %d/%d  Toys: %d/%d" % [
		food_items.get_child_count(),
		FOOD_LIMIT,
		toy_items.get_child_count(),
		TOY_LIMIT
	]
	hint_label.text = "Player at (%.0f, %.0f). Drop food near a hungry dog or a toy near Buster to trigger a reaction." % [
		player.position.x,
		player.position.y
	]
	dog_status_label.text = _build_dog_status_text()


func _get_item_container(item_type: String) -> Node2D:
	return food_items if item_type == "food" else toy_items


func _build_dog_status_text() -> String:
	var lines := ["Pack Status"]
	for child in dogs_container.get_children():
		if child.has_method("get_snapshot"):
			var snapshot: Dictionary = child.get_snapshot()
			lines.append("%s | %s" % [snapshot["dog_name"], snapshot["thought"]])
			lines.append("H %.0f  E %.0f  M %.0f" % [
				snapshot["hunger"],
				snapshot["energy"],
				snapshot["happiness"]
			])
			lines.append("Trust %.0f | %s" % [
				snapshot["trust"],
				snapshot["last_event"]
			])
	return "\n".join(lines)


func _get_nearest_dog(max_distance := 72.0) -> Node2D:
	var nearest_dog: Node2D = null
	var best_distance := max_distance * max_distance
	for child in dogs_container.get_children():
		var dog := child as Node2D
		var distance_to_dog := player.position.distance_squared_to(dog.global_position)
		if distance_to_dog < best_distance:
			best_distance = distance_to_dog
			nearest_dog = dog
	return nearest_dog


func _pet_nearest_dog() -> void:
	var dog := _get_nearest_dog()
	if dog != null and dog.has_method("react_to_pet"):
		dog.react_to_pet()
		_bump_camera(3.5)


func _whistle_pack() -> void:
	for child in dogs_container.get_children():
		if child.has_method("hear_whistle"):
			child.hear_whistle(player.position)
	_bump_camera(4.5)


func _update_camera(delta: float) -> void:
	camera_shake = move_toward(camera_shake, 0.0, delta * 18.0)
	if camera_shake > 0.05:
		camera.offset = Vector2(randf_range(-camera_shake, camera_shake), randf_range(-camera_shake, camera_shake))
	else:
		camera.offset = Vector2.ZERO


func _bump_camera(amount: float) -> void:
	camera_shake = minf(camera_shake + amount, 10.0)


func _draw_hud_backplates() -> void:
	draw_rect(Rect2(Vector2(16.0, 12.0), Vector2(628.0, 112.0)), Color(1, 1, 1, 0.32), true)
	draw_rect(Rect2(Vector2(926.0, 12.0), Vector2(336.0, 190.0)), Color(1, 1, 1, 0.28), true)
	draw_rect(Rect2(Vector2(18.0, 660.0), Vector2(700.0, 52.0)), Color(1, 1, 1, 0.28), true)


func _draw_world_gizmos() -> void:
	draw_rect(PLAY_AREA, Color("2b7a78", 0.28), false, 2.0)
	for child in dogs_container.get_children():
		if child.has_method("draw_debug_gizmo"):
			child.draw_debug_gizmo()


func _draw_player() -> void:
	draw_circle(player.position + Vector2(0.0, 14.0), 14.0, Color(0, 0, 0, 0.12))
	draw_circle(player.position, 20.0, Color("2b7a78"))
	draw_circle(player.position + Vector2(0.0, -26.0), 12.0, Color("17252a"))
	draw_line(player.position + Vector2(0.0, -8.0), player.position + Vector2(0.0, 28.0), Color("17252a"), 5.0, true)
	draw_line(player.position + Vector2(0.0, 4.0), player.position + Vector2(-18.0, 18.0), Color("17252a"), 4.0, true)
	draw_line(player.position + Vector2(0.0, 4.0), player.position + Vector2(18.0, 18.0), Color("17252a"), 4.0, true)
	draw_line(player.position + Vector2(0.0, 28.0), player.position + Vector2(-15.0, 48.0), Color("17252a"), 4.0, true)
	draw_line(player.position + Vector2(0.0, 28.0), player.position + Vector2(15.0, 48.0), Color("17252a"), 4.0, true)
	draw_string(ThemeDB.fallback_font, player.position + Vector2(-30.0, -42.0), "Player", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("17252a"))


func _draw_fence() -> void:
	var post_color := Color("896744")
	for x in range(60, 1210, 58):
		draw_line(Vector2(x, 92.0), Vector2(x, 124.0), post_color, 4.0, true)
		draw_line(Vector2(x, 644.0), Vector2(x, 676.0), post_color, 4.0, true)
	for y in range(128, 644, 52):
		draw_line(Vector2(48.0, y), Vector2(48.0, y + 22.0), post_color, 4.0, true)
		draw_line(Vector2(1232.0, y), Vector2(1232.0, y + 22.0), post_color, 4.0, true)
	draw_line(Vector2(48.0, 108.0), Vector2(1232.0, 108.0), post_color, 4.0, true)
	draw_line(Vector2(48.0, 662.0), Vector2(1232.0, 662.0), post_color, 4.0, true)


func _draw_clouds() -> void:
	for i in range(4):
		var x := fmod(day_time * (8.0 + i * 2.0) + i * 330.0, WORLD_SIZE.x + 160.0) - 80.0
		var y := 42.0 + i % 2 * 32.0
		var cloud_color := Color(1, 1, 1, 0.62)
		draw_circle(Vector2(x, y), 22.0, cloud_color)
		draw_circle(Vector2(x + 24.0, y - 6.0), 28.0, cloud_color)
		draw_circle(Vector2(x + 54.0, y), 20.0, cloud_color)


func _draw_grass_texture() -> void:
	var blade_color := Color("8eaa68")
	for x in range(76, 1210, 44):
		var offset := int(sin(float(x) * 0.07) * 14.0)
		for y in range(140 + abs(offset), 626, 86):
			draw_line(Vector2(x, y), Vector2(x + 5.0, y - 13.0), blade_color, 2.0, true)
			draw_line(Vector2(x + 8.0, y), Vector2(x + 2.0, y - 11.0), blade_color.darkened(0.08), 2.0, true)


func _draw_enrichment_spots() -> void:
	for dog_name in ENRICHMENT_SPOTS:
		for spot in ENRICHMENT_SPOTS[dog_name]:
			draw_circle(spot, 18.0, Color(1.0, 1.0, 1.0, 0.10))
			draw_arc(spot, 24.0, 0.0, TAU, 24, Color("ffffff", 0.26), 2.0)


func _draw_bed(dog_name: String, position: Vector2, base_color: Color, pillow_color: Color) -> void:
	draw_circle(position + Vector2(0.0, 10.0), 34.0, Color(0, 0, 0, 0.08))
	draw_circle(position, 34.0, base_color.darkened(0.12))
	draw_circle(position, 24.0, pillow_color)
	draw_string(ThemeDB.fallback_font, position + Vector2(-34.0, -42.0), "%s bed" % dog_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("4f4336"))


func _draw_zone(position: Vector2, size: Vector2, color: Color, label_text: String) -> void:
	draw_rect(Rect2(position, size), color.darkened(0.08), true)
	draw_rect(Rect2(position + Vector2(10.0, 10.0), size - Vector2(20.0, 20.0)), color.lightened(0.25), true)
	draw_string(ThemeDB.fallback_font, position + Vector2(18.0, 36.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffffff"))
