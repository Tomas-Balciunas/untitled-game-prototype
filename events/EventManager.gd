extends Node

signal start_event_encounter(data: Dictionary)

@onready var party_panel = get_tree().get_root().get_node("Main/PartyPanel")
var current_event: Array = []
var event_step: int = 0

func process_event(event_id: String):
	var event = EventRegistry.get_event(event_id)
	
	if not event or EventFlags.is_event_completed(event_id):
		return
	
	party_panel.disable_party_ui()
	current_event = event
	
	for sequence in event:
		event_step += 1
		match sequence["type"]:
			"text":
				await handle_text(sequence)
			"encounter":
				await handle_encounter(sequence)
	
	current_event = []
	event_step = 0
	party_panel.enable_party_ui()
	EventFlags.mark_event_completed(event_id)

func is_event(tile_data: Dictionary):
	return "event" in tile_data and tile_data["event"]

func handle_text(sequence: Dictionary):
	var speaker = sequence.get("speaker", "Unknown Entity")
	
	for line in sequence["text"]:
		await get_textbox_ui().show_text(speaker, line)
	
func handle_encounter(sequence):
	var arena = sequence["arena"]
	emit_signal("start_event_encounter", { "arena": arena })
	party_panel.enable_party_ui()
	await EncounterManager.encounter_ended
	if not current_event.is_empty() and current_event.size() > event_step:
		party_panel.disable_party_ui()
	

func get_textbox_ui() -> Node:
	var scene = get_tree().current_scene
	if scene and scene.has_node("UIRoot/TextboxUI"):
		return scene.get_node("UIRoot/TextboxUI")
	else:
		push_warning("TextboxUI not found!")
		return null
