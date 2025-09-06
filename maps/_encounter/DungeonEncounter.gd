extends Node3D

@export var encounter_data: EncounterData
@export var enemy_scene: PackedScene
@onready var encounter_area: BattleTrigger = $EncounterArea

func _ready():
	assert(encounter_data)
	assert(enemy_scene)
	
	if MapInstance.is_encounter_cleared(MapInstance.map_id, encounter_data.id):
		queue_free()
		return
	
	encounter_area.encounter = encounter_data
	var visual = enemy_scene.instantiate()
	add_child(visual)
	visual.get_node("Sprite").play("idle")
