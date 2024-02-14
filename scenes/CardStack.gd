extends Node2D

@export var is_self: bool = false


func reset(card: Card):
	if not is_self:
		for child in get_children():
			if child is Card:
				child.is_check = false
		card.is_check = true
