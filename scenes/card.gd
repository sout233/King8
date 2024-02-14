extends Node2D

class_name Card

@export var card_sprite: Sprite2D

var card_color: int

var card_name: String = "idk":
	set(value):
		card_name = value
		update_card()

var is_check: bool:
	set(value):
		is_check = value
		update_check_state()

var checkable: bool = true
var is_mouse_over: bool
var rem_pos: Vector2
var card_index: int


func _ready():
	rem_pos = position


func _process(_delta) -> void:
	if Input.is_action_just_pressed("click") and is_mouse_over and checkable:
		is_check = not is_check
		get_parent().reset(self)


func update_card() -> void:
	var texture: CompressedTexture2D = load(King8Helper.get_card_path(card_name, card_color))
	if card_name != "idk":
		card_sprite.texture = texture


func update_check_state() -> void:
	if is_check:
		modulate = Color(0.8, 0.8, 0.8, 1)
		position.y = rem_pos.y - 10
	else:
		modulate = Color(1, 1, 1, 1)
		position.y = rem_pos.y


func _on_mouse_entered() -> void:
	is_mouse_over = true
	if Input.get_action_raw_strength("click") > 0 and checkable:
		is_check = not is_check
		get_parent().reset(self)


func _on_mouse_exited() -> void:
	is_mouse_over = false
