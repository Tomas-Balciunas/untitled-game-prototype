extends Node

const TEXT = "text"

var party_panel: Node
var current_event: Array = []
var event_step: int = 0
var choices: Array = []

func process_event(data: Variant) -> EventContext:
	GameState.set_event()
	var event: Variant
	var ctx = EventContext.new()
	choices = []
	
	if data is String:
		if EventFlags.is_event_completed(data):
			GameState.set_idle()
			return
			
		event = EventRegistry.get_event(data)
	elif data is Array:
		event = data
	else:
		push_warning("Event has an incorrect type")
		event = [{
			"type": "text",
			"speaker": "System",
			"text": [
				"Error: broken event"
				]
			}]
	
	if event.is_empty():
		GameState.set_idle()
		return
		
	party_panel = get_tree().get_root().get_node("Main/PartyPanel")
	party_panel.disable_party_ui()
	
	for step_data: Dictionary in event:
		var step := EventFactory.create_step(step_data)
		if step:
			await step.run(self)
		else:
			push_error("Error getting event step: %s" % step_data)
	
	party_panel.enable_party_ui()
	
	if data is String:
		EventFlags.mark_event_completed(data)
		
	GameState.set_idle()
	
	return ctx
