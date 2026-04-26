extends Node

## { quest_id: String -> QuestInstance }
var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var failed_quests: Array[String] = []


func _ready() -> void:
	BattleBus.enemy_died.connect(_on_enemy_died)


func start_quest(quest_id: String) -> QuestInstance:
	if active_quests.has(quest_id):
		push_warning("Quest already active: %s" % quest_id)
		return active_quests[quest_id]

	if completed_quests.has(quest_id):
		push_warning("Quest already completed: %s" % quest_id)
		return null

	var quest: Quest = QuestRegistry.get_quest(quest_id)
	if not quest:
		return null

	var inst := QuestInstance.new(quest)
	active_quests[quest_id] = inst
	QuestBus.quest_started.emit(quest_id)
	return inst


func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		push_warning("Cannot complete quest that is not active: %s" % quest_id)
		return

	var inst: QuestInstance = active_quests[quest_id]
	inst.status = QuestInstance.Status.COMPLETED
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)

	_apply_rewards(inst)
	QuestBus.quest_completed.emit(quest_id)


func fail_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return

	var inst: QuestInstance = active_quests[quest_id]
	inst.status = QuestInstance.Status.FAILED
	active_quests.erase(quest_id)
	failed_quests.append(quest_id)
	QuestBus.quest_failed.emit(quest_id)


func update_objective(quest_id: String, objective_id: String, amount: int = 1) -> void:
	var inst: QuestInstance = active_quests.get(quest_id)
	if not inst:
		return

	inst.add_progress(objective_id, amount)
	QuestBus.quest_objective_updated.emit(quest_id, objective_id)

	if inst.are_all_objectives_done():
		complete_quest(quest_id)


## Advance all MANUAL objectives matching objective_id across all active quests.
func advance_objective(objective_id: String, amount: int = 1) -> void:
	for quest_id: String in active_quests.keys():
		var inst: QuestInstance = active_quests[quest_id]
		for obj: QuestObjective in inst.quest.objectives:
			if obj.id == objective_id:
				update_objective(quest_id, objective_id, amount)


func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)


func is_quest_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)


func get_active_quest(quest_id: String) -> QuestInstance:
	return active_quests.get(quest_id)


func _on_enemy_died(dead: CharacterInstance) -> void:
	var enemy_id: String = dead.resource.id
	for quest_id: String in active_quests.keys():
		var inst: QuestInstance = active_quests[quest_id]
		for obj: QuestObjective in inst.quest.objectives:
			if obj.type == QuestObjective.Type.KILL_ENEMY and obj.target_id == enemy_id:
				update_objective(quest_id, obj.id, 1)


func _apply_rewards(inst: QuestInstance) -> void:
	if not inst.quest.reward:
		return

	var reward: QuestReward = inst.quest.reward

	for member: CharacterInstance in PartyManager.get_all_members():
		if reward.experience > 0:
			member.current_experience += reward.experience

		for effect: Effect in reward.effects:
			member.apply_effect(effect, CharacterSource.new(member))

	# Item rewards go to the first party member's inventory for now
	if not reward.items.is_empty():
		var leader: CharacterInstance = PartyManager.get_all_members().front()
		if leader:
			for item: Item in reward.items:
				if item is Gear:
					leader.inventory.add_item(item._build_instance())


func game_save() -> Dictionary:
	var active: Array = []
	for inst: QuestInstance in active_quests.values():
		active.append(inst.to_dict())

	return {
		"active": active,
		"completed": completed_quests.duplicate(),
		"failed": failed_quests.duplicate()
	}


func game_load(data: Dictionary) -> void:
	active_quests = {}
	completed_quests = data.get("completed", [])
	failed_quests = data.get("failed", [])

	for inst_data: Dictionary in data.get("active", []):
		var inst := QuestInstance.from_dict(inst_data)
		if inst:
			active_quests[inst.quest.id] = inst
