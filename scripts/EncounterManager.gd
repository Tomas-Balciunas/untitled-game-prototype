extends Node

@onready var transition_battle: ColorRect = $BattleTransition

var battle_scene: PackedScene = preload("res://scenes/BattleScene.tscn")
var current_battle_scene: BattleScene = null

func _ready() -> void:
	EncounterBus.encounter_started.connect(start_encounter)
	EncounterBus.encounter_ended.connect(end_encounter)

func start_encounter(data: EncounterData) -> void:
	if GameState.current_state not in [GameState.States.IDLE, GameState.States.EVENT]:
		return
		
	GameState.current_state = GameState.States.IN_BATTLE
	print("EncounterManager: Starting encounter:", data.id)
	
	var enemies: Array[CharacterResource] = []
	var arena := MapManager.get_arena(data.arena)
	
	for enemy in data.enemies:
		enemies.append(CharacterRegistry.get_character(enemy.id))
	
	var tween := get_tree().create_tween()
	transition_battle.modulate.a = 0.0
	transition_battle.visible = true
	tween.tween_property(transition_battle, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	current_battle_scene = battle_scene.instantiate()
	get_tree().get_root().get_node("Main").add_child(current_battle_scene)
	current_battle_scene.global_position = Vector3(1000, 0, 1000)
	current_battle_scene.initiate(arena, enemies, data)
	
	tween = get_tree().create_tween()
	tween.tween_property(transition_battle, "modulate:a", 0.0, 0.5)
	transition_battle.visible = false
	await tween.finished

func end_encounter(result: String, data: EncounterData) -> void:
	if result == "win":
		MapInstance.mark_encounter_cleared(data.id)

	current_battle_scene.queue_free()
	get_tree().get_root().get_node("Main").remove_child(current_battle_scene)
	current_battle_scene = null
	print("EncounterManager: Ending encounter with result:", result)
	BattleContext.clear_context()
	print(data)

	if result == "win":
		if data.reward_event != null:
			await EventManager.process_event(data.reward_event)
		else:
			var default_steps := _build_default_reward_steps(data)
			if not default_steps.is_empty():
				await EventManager.process_event(default_steps)

		PartyManager.grant_experience_to_all(data.experience_reward)

	GameState.current_state = GameState.States.IDLE


func _build_default_reward_steps(data: EncounterData) -> Array[EventStep]:
	var b := EventBuilder.new()

	if data.gold_reward > 0:
		b.say("", ["Obtained %d gold." % data.gold_reward]).give_gold(data.gold_reward, false)

	for item_resource: ItemResource in data.item_rewards:
		if item_resource == null:
			continue
		b.say("", ["Obtained %s." % item_resource.name]).give_item(item_resource, false)

	return b.build()
