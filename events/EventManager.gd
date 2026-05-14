extends Node

var choices: Array[String] = []
var subject: BaseCharacterResource = null


func process_event(data: Variant, p_subject: BaseCharacterResource = null) -> EventContext:
	GameState.set_event()
	choices = []
	subject = p_subject

	var steps: Array[EventStep] = []
	var completion_id := ""

	if data is String:
		if EventFlags.is_event_completed(data):
			subject = null
			GameState.set_idle()
			return _empty_context()

		var ev := EventRegistry.get_event(data)
		if ev == null:
			subject = null
			GameState.set_idle()
			return _empty_context()

		steps = ev.steps
		completion_id = data
	elif data is EventResource:
		steps = (data as EventResource).steps
		completion_id = (data as EventResource).id
	elif data is Array:
		steps = _coerce_step_array(data)
	else:
		push_warning("Event has an incorrect type: %s" % data)
		subject = null
		GameState.set_idle()
		return _empty_context()

	for step in steps:
		if step == null:
			push_error("Null step in event")
			continue
		if not step.should_run(self):
			continue
		await step.run(self)

	if completion_id != "":
		EventFlags.mark_event_completed(completion_id)

	GameState.set_idle()
	ConversationBus.event_concluded.emit()
	var ctx := _build_context()
	subject = null
	return ctx


func _build_context() -> EventContext:
	var ctx := EventContext.new()
	ctx.choices = choices.duplicate()
	return ctx


func _empty_context() -> EventContext:
	return EventContext.new()


func _coerce_step_array(arr: Array) -> Array[EventStep]:
	var typed: Array[EventStep] = []
	for s in arr:
		if s is EventStep:
			typed.append(s)
		else:
			push_error("Event step is not an EventStep resource: %s" % s)
	return typed
