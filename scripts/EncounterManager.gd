extends Node

signal encounter_started(encounter_data)
signal encounter_ended(result)

@onready var transition_battle = get_tree().get_root().get_node("Main/BattleTransition")

var encounter_in_progress: bool = false
var battle_scene: PackedScene = preload("res://scenes/BattleScene.tscn")
var current_battle_scene: BattleScene = null

func _ready():
	#var player = get_tree().get_root().get_node("Main/Dungeon/Player")
	#player.connect("start_encounter", Callable(EncounterManager, "start_encounter"))
	EventManager.connect("start_event_encounter", Callable(self, "start_encounter"))
	transition_battle.modulate.a = 0.0

func start_encounter(encounter_data: Dictionary):
	if encounter_in_progress:
		return
		
	encounter_in_progress = true
	print("EncounterManager: Starting encounter:", encounter_data)
	var arena_id = encounter_data["arena"]
	var enemy_ids = encounter_data["enemies"]
	var enemies: Array[CharacterResource] = []
	var arena = MapManager.get_arena(arena_id)
	
	for id in enemy_ids:
		enemies.append(CharacterRegistry.get_character(id))
	
	var tween = get_tree().create_tween()
	tween.tween_property(transition_battle, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	current_battle_scene = battle_scene.instantiate()
	get_tree().get_root().get_node("Main").add_child(current_battle_scene)
	current_battle_scene.initiate(arena, enemies)
	emit_signal("encounter_started", encounter_data)
	
	tween = get_tree().create_tween()
	tween.tween_property(transition_battle, "modulate:a", 0.0, 0.5)
	await tween.finished

func end_encounter(result):
	get_tree().get_root().get_node("Main").remove_child(current_battle_scene)
	current_battle_scene = null
	print("EncounterManager: Ending encounter with result:", result)
	emit_signal("encounter_ended", result)
	encounter_in_progress = false
