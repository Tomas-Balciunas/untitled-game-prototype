extends Node3D

#@onready var tiles_container = $TilesContainer
@onready var battle_manager = $BattleManager

var encounter_data

#func _ready():
	#load_arena_visuals()
	#battle_manager.start_battle(encounter_data)

func load_arena_visuals():
	var arena_scene = MapManager.arenas["default"]
	var arena_instance = arena_scene.instantiate()
	#tiles_container.add_child(arena_instance)
