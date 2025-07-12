extends Node

var completed_events: Array = []

func is_event_completed(event_id: String):
	return completed_events.has(event_id)

func mark_event_completed(event_id: String):
	completed_events.append(event_id)
