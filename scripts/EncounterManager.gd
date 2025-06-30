extends Node

signal encounter_started(encounter_data)
signal encounter_ended(result)

@onready var transition_battle = get_tree().get_root().get_node("Main/BattleTransition")

var current_battle_scene: Node = null

func _ready():
	transition_battle.modulate.a = 0.0

func is_encounter(tile: Dictionary):
	return "encounter" in tile and tile["encounter"] 

func start_encounter(encounter_data: Dictionary):
	print("EncounterManager: Starting encounter:", encounter_data)
	
	var tween = get_tree().create_tween()
	tween.tween_property(transition_battle, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	current_battle_scene = preload("res://maps/arena/default/arena_default.tscn").instantiate()
	get_tree().get_root().get_node("Main").add_child(current_battle_scene)
	emit_signal("encounter_started", encounter_data)
	
	tween = get_tree().create_tween()
	tween.tween_property(transition_battle, "modulate:a", 0.0, 0.5)
	await tween.finished

func end_encounter(result):
	print("EncounterManager: Ending encounter with result:", result)
	
	#if current_battle_scene and current_battle_scene.is_inside_tree():
		#current_battle_scene.queue_free()
		#current_battle_scene = null
	
	# Show dungeon again
	#var dungeon = get_tree().get_root().get_node("Main/Dungeon")
	#dungeon.visible = true
	
	# You might want to reset player states, reposition, or restore map here
	
	emit_signal("encounter_ended", result)
