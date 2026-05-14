extends Resource

class_name InteractionEntry


@export var id: String = ""
@export var priority: int = 0
@export var random_pick: bool = false
@export var idle: bool = false
@export var conditions: Array[InteractionCondition] = []
@export var steps: Array[EventStep] = []


func matches(c: BaseCharacterResource) -> bool:
	for cond: InteractionCondition in conditions:
		if not cond.matches(c):
			return false

	return true
