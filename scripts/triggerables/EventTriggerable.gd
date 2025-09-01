extends Triggerable
class_name EventTrigger

@export var event_id: String

func _fire(_data: Dictionary):
	EventManager.process_event(event_id)
