extends Node

@onready var party_panel = get_tree().get_root().get_node("Main/PartyPanel")
var current_event: Array = []
var event_step: int = 0

func process_event(event_id: String):
	GameState.set_event()
	var event = EventRegistry.get_event(event_id)
	
	if not event or EventFlags.is_event_completed(event_id):
		GameState.set_idle()
		return
	
	party_panel.disable_party_ui()
	
	for step_data in event:
		var step = EventFactory.create_step(step_data)
		if step:
			await step.run(self)
		else:
			push_error("Error getting event step: %s" % step_data)
	
	party_panel.enable_party_ui()
	EventFlags.mark_event_completed(event_id)
	GameState.set_idle()
