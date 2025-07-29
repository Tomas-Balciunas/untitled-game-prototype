extends Area3D

func _ready():
	self.connect("body_entered", Callable(self, "_on_player_entered_area"))

func _on_player_entered_area(body):
	if body.is_in_group("player"):
		RestManager.on_rest_button_pressed()
		
