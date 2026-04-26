extends Resource

class_name Quest

@export var id: String
@export var name: String
@export var description: String
@export var objectives: Array[QuestObjective] = []
@export var reward: QuestReward
