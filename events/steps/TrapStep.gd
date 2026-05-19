extends EventStep
class_name TrapStep

@export var trap: Trap

var target: Character


func run(_manager: EventManager) -> void:
	if trap == null:
		push_error("TrapStep has no trap set")
		return
	trap.trigger(target)
