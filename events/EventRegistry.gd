extends Node

var _events: Dictionary = {}


func _ready() -> void:
	_register(TestEvent000.build())


func get_event(id: String) -> EventResource:
	if not _events.has(id):
		push_warning("Event not found: %s" % id)
		return null
	return _events[id]


func has_event(id: String) -> bool:
	return _events.has(id)


func _register(event: EventResource) -> void:
	if event == null:
		push_error("EventRegistry._register received null")
		return
	if event.id == "":
		push_error("EventRegistry._register received event with empty id")
		return
	if _events.has(event.id):
		push_error("EventRegistry: duplicate event id %s" % event.id)
		return
	_events[event.id] = event
