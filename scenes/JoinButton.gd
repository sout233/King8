extends Button


func _ready():
	pressed.connect(MultiplayController.join_game)
