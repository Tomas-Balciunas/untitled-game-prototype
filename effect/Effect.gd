extends Resource

class_name Effect

@export_category("Effect")

enum Trigger {
	APPLY,
	TURN_START,
	ACTION,
	DAMAGE_RECEIVED,
	TURN_END,
	EXPIRE
}

var owner: CharacterInstance
var duration := 0
var stacks := 1

func _init(_owner: CharacterInstance, _duration: int=1):
	owner = _owner
	duration = _duration

func on_apply() -> void:
	pass

func on_turn_start() -> void:
	pass

func on_action(event_data: Dictionary) -> void:
	pass

func on_damage_received(event_data: Dictionary) -> void:
	pass

func on_turn_end() -> void:
	duration -= 1
	if duration <= 0:
		on_expire()

func on_expire() -> void:
	owner.effects.erase(self)
