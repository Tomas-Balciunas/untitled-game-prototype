extends Node

@onready var transition_battle: ColorRect = $BattleTransition

var battle_scene: PackedScene = preload("res://scenes/BattleScene.tscn")
var current_battle_scene: BattleScene = null

func _ready() -> void:
	EncounterBus.encounter_started.connect(start_encounter)
	EncounterBus.encounter_ended.connect(end_encounter)

func start_encounter(data: EncounterData):
	if GameState.current_state not in [GameState.States.IDLE, GameState.States.EVENT]:
		return
		
	GameState.current_state = GameState.States.IN_BATTLE
	print("EncounterManager: Starting encounter:", data.id)
	
	var enemies: Array[CharacterResource] = []
	var arena = MapManager.get_arena(data.arena)
	
	for enemy in data.enemies:
		enemies.append(CharacterRegistry.get_character(enemy.id))
	
	var tween = get_tree().create_tween()
	transition_battle.modulate.a = 0.0
	transition_battle.visible = true
	tween.tween_property(transition_battle, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	current_battle_scene = battle_scene.instantiate()
	get_tree().get_root().get_node("Main").add_child(current_battle_scene)
	current_battle_scene.initiate(arena, enemies, data)
	
	tween = get_tree().create_tween()
	tween.tween_property(transition_battle, "modulate:a", 0.0, 0.5)
	transition_battle.visible = false
	await tween.finished

func end_encounter(result):
	if result == "win":
		MapInstance.mark_encounter_cleared(MapInstance.map_id, BattleContext.encounter_data.id)
		
		#TODO find a better place
		for member in PartyManager.members:
			member.resource.experience_manager.grant_experience_to_character(member, BattleContext.encounter_data.experience_reward)
	
	current_battle_scene.queue_free()
	get_tree().get_root().get_node("Main").remove_child(current_battle_scene)
	current_battle_scene = null
	print("EncounterManager: Ending encounter with result:", result)
	#EncounterBus.encounter_ended.emit(result)
	BattleContext.clear_context()
	GameState.current_state = GameState.States.IDLE
