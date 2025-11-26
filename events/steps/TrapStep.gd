extends EventStep
class_name TrapStep

var id: String
var trap: Trap
var target: CharacterInstance

func _init(data: Dictionary) -> void:
	trap = data.get("trap")
	target = data.get("target")

func run(_manager: EventManager) -> void:
	trap.trigger(target)
