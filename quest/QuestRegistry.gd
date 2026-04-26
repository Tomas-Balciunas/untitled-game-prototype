extends Node

var quests: Dictionary = {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths: Array[String] = [
		# "res://quest/data/example_quest.tres"
	]

	for path: String in res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_quest(res)

func register_quest(quest: Quest) -> void:
	if quest.id in quests:
		push_warning("Duplicate quest id: %s" % quest.id)
	quests[quest.id] = quest

func get_quest(id: String) -> Quest:
	if quests.has(id):
		return quests[id]
	push_error("Quest not found: %s" % id)
	return null

func get_all() -> Array:
	return quests.values()
