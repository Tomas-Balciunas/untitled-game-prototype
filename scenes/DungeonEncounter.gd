extends Node3D

var encounter_id: String
@export var encounter_data: EncounterData
@export var enemy_scene: PackedScene
@onready var encounter_area = $EncounterArea

func _ready():
	assert(encounter_data)
	assert(enemy_scene)
	encounter_id = encounter_data.id
	
	if MapInstance.is_encounter_cleared(MapInstance.map_id, encounter_id):
		queue_free()
		return

	var visual = enemy_scene.instantiate()
	add_child(visual)
	encounter_area.connect(
		"body_entered",
		Callable(self, "_on_player_entered_area")
	)

func _on_player_entered_area(body):
	if body.is_in_group("player"):
		if not encounter_data:
			push_error("Starting encouter error: no EncounterData found!")
			
		
		var arena = encounter_data.arena
		var enemies = encounter_data.enemies.map(func(e: CharacterResource): return e.id)
		
		EncounterManager.start_encounter({"arena": arena, "enemies": enemies, "id": encounter_id})
