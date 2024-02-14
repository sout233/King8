extends Button


func _ready():
	pressed.connect(MultiplayController.create_game)
