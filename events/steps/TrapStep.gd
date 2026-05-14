extends EventStep
class_name TrapStep

@export var trap: Trap

var target: Character


func run(_manager: EventManager) -> void:
	if trap == null:
		push_error("TrapStep has no trap set")
		return
	trap.trigger(target)


static func against(p_trap: Trap, p_target: Character) -> TrapStep:
	var s := TrapStep.new()
	s.trap = p_trap
	s.target = p_target
	return s
