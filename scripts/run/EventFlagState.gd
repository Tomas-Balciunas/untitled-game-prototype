extends RefCounted

class_name EventFlagState

var completed_events: Array = []

func is_event_completed(event_id: String) -> bool:
	return completed_events.has(event_id)

func mark_event_completed(event_id: String) -> void:
	completed_events.append(event_id)

func game_save() -> Dictionary:
	return {"completed_events": completed_events}

func game_load(data: Dictionary) -> void:
	completed_events = data.get("completed_events", [])
