@abstract
extends Resource
class_name EventStep

@export var conditions: Array[String] = []
@export var world_conditions: Array[InteractionCondition] = []


func should_run(manager: EventManager) -> bool:
	for c in conditions:
		if not manager.choices.has(c):
			return false

	if not world_conditions.is_empty():
		if manager.subject == null:
			push_warning("EventStep has world_conditions but EventManager has no subject")
			return false
		for wc in world_conditions:
			if not wc.matches(manager.subject):
				return false

	return true


@abstract
func run(_manager: EventManager) -> void


func when(p_conditions: Array[String]) -> EventStep:
	conditions = p_conditions
	return self


func only_if(p_world_conditions: Array[InteractionCondition]) -> EventStep:
	world_conditions = p_world_conditions
	return self
