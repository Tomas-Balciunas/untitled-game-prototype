extends StaticBody3D

@export var arena_name = "arena_default_00"
@export var enemy_name = "Goblin"

func _ready():
	$EncounterArea.connect("body_entered", Callable(self, "_on_player_entered_area"))

func _on_player_entered_area(body):
	if body.is_in_group("player"):
		EncounterManager.start_encounter({"arena": arena_name, "enemy": enemy_name})
