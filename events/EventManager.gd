extends Node

signal start_event_encounter(data: Dictionary)

func process_event(event_id: String):
	var event = EventRegistry.get_event(event_id)
	
	if not event or EventFlags.is_event_completed(event_id):
		return
	
	for sequence in event:
		match sequence["type"]:
			"text":
				await handle_text(sequence)
			"encounter":
				await handle_encounter(sequence)
	
	EventFlags.mark_event_completed(event_id)

func is_event(tile_data: Dictionary):
	return "event" in tile_data and tile_data["event"]

func handle_text(sequence):
	var speaker = sequence["speaker"]
	
	for text in sequence["text"]:
		print("%s: %s" % [speaker, text])
	
func handle_encounter(sequence):
	var arena = sequence["arena"]
	emit_signal("start_event_encounter", { "arena": arena })
	await EncounterManager.encounter_ended
