extends Node2D
class_name WorldItemNode

@export_enum("food", "toy") var item_type := "food"
@export var radius := 16.0
@export var item_color := Color("d96c5f")
@export var accent_color := Color("f7d488")
@export var label_text := "Food"

@onready var label: Label = $Label

var pulse_time := 0.0
var bump_amount := 0.0
var lifetime := 0.0
var age := 0.0


func configure(new_item_type: String, spawn_position: Vector2) -> void:
	item_type = new_item_type
	global_position = spawn_position
	if item_type == "food":
		item_color = Color("d96c5f")
		accent_color = Color("f6d77b")
		label_text = "Food"
		lifetime = 18.0
	else:
		item_color = Color("5aa6d6")
		accent_color = Color("e8f4ff")
		label_text = "Toy"
		lifetime = 28.0


func _ready() -> void:
	label.text = label_text


func _process(delta: float) -> void:
	pulse_time += delta * 2.4
	age += delta
	bump_amount = move_toward(bump_amount, 0.0, delta * 3.0)
	if age >= lifetime:
		queue_free()
		return
	queue_redraw()


func bump() -> void:
	bump_amount = 1.0


func _draw() -> void:
	var scale_amount := 1.0 + sin(pulse_time) * 0.05 + bump_amount * 0.18
	var fade := clampf(1.0 - (age / max(lifetime, 0.01)) * 0.55, 0.3, 1.0)
	draw_circle(Vector2.ZERO, radius * scale_amount, item_color * Color(1, 1, 1, fade))
	if item_type == "food":
		draw_circle(Vector2(0.0, -2.0), radius * 0.42 * scale_amount, accent_color * Color(1, 1, 1, fade))
	else:
		draw_circle(Vector2.ZERO, radius * 0.52 * scale_amount, accent_color * Color(1, 1, 1, fade))
