extends RefCounted

class_name QuestInstance

enum Status { ACTIVE, COMPLETED, FAILED }

var quest: Quest
var status: Status = Status.ACTIVE
## { objective_id: String -> current_count: int }
var objective_progress: Dictionary = {}


func _init(q: Quest) -> void:
	quest = q
	for obj: QuestObjective in q.objectives:
		objective_progress[obj.id] = 0


func get_objective_progress(objective_id: String) -> int:
	return objective_progress.get(objective_id, 0)


func add_progress(objective_id: String, amount: int = 1) -> void:
	if not objective_progress.has(objective_id):
		return
	var obj := _get_objective(objective_id)
	if not obj:
		return
	objective_progress[objective_id] = mini(
		objective_progress[objective_id] + amount,
		obj.required_count
	)


func is_objective_done(objective_id: String) -> bool:
	var obj := _get_objective(objective_id)
	if not obj:
		return false
	return objective_progress.get(objective_id, 0) >= obj.required_count


func are_all_objectives_done() -> bool:
	for obj: QuestObjective in quest.objectives:
		if not is_objective_done(obj.id):
			return false
	return true


func _get_objective(objective_id: String) -> QuestObjective:
	for obj: QuestObjective in quest.objectives:
		if obj.id == objective_id:
			return obj
	return null


func to_dict() -> Dictionary:
	return {
		"quest_id": quest.id,
		"status": status,
		"progress": objective_progress.duplicate()
	}


static func from_dict(data: Dictionary) -> QuestInstance:
	var q: Quest = QuestRegistry.get_quest(data["quest_id"])
	if not q:
		push_error("Quest not found: %s" % data["quest_id"])
		return null
	var inst := QuestInstance.new(q)
	inst.status = data.get("status", Status.ACTIVE)
	var saved_progress: Dictionary = data.get("progress", {})
	for key: String in saved_progress:
		if inst.objective_progress.has(key):
			inst.objective_progress[key] = saved_progress[key]
	return inst
