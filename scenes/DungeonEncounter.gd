extends StaticBody3D

@export var encounter_data: EncounterData

func _ready():
	$EncounterArea.connect("body_entered", Callable(self, "_on_player_entered_area"))

func _on_player_entered_area(body):
	if body.is_in_group("player"):
		if not encounter_data:
			push_error("Starting encouter error: no EncounterData found!")
			
		var arena = encounter_data.arena
		var enemies = encounter_data.enemies.map(func(e: CharacterResource): return e.id)
		
		EncounterManager.start_encounter({"arena": arena, "enemies": enemies})
