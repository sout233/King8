extends Node

@export var draw_button:Button

var is_card_ready = false

func _process(_delta):
    if MultiplayController.round_id!=multiplayer.get_unique_id():
        draw_button.disabled = true
    else:
        draw_button.disabled = false
