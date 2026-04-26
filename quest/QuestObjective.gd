extends Resource

class_name QuestObjective

enum Type {
	KILL_ENEMY,
	COLLECT_ITEM,
	TALK_TO_NPC,
	REACH_LOCATION,
	MANUAL
}

@export var id: String
@export var description: String
@export var type: Type = Type.MANUAL
@export var target_id: String = ""
@export var required_count: int = 1
