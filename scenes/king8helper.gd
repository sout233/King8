extends Node


func get_card_path(value: String, color: int=0) -> String:
	if value == "jk":
		return "res://assests/cards/Joker_1.png"
	elif value == null or value == "":
		return "res://assests/cards/Back_1.png"

	var color_str
	if color == 1:
		color_str = "Clubs"
	elif color == 2:
		color_str = "Diamonds"
	elif color == 3:
		color_str = "Hearts"
	elif color == 4:
		color_str = "Spades"
	else:
		color_str = "Clubs"

	return "res://assests/cards/" + color_str + "_" + value + ".png"
