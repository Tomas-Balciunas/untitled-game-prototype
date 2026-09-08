extends Node

var choices: Array[String] = []
var subject: BaseCharacterResource = null

var _queue: Array[EventRequest] = []
var _running: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func process_event(data: Variant, p_subject: BaseCharacterResource = null) -> void:
	var request := EventRequest.new()
	request.data = data
	request.subject = p_subject
	_queue.append(request)

	if not _running:
		_drain()

	if not request.completed:
		await request.finished


func pause_tree() -> void:
	get_tree().paused = true


func run_tree() -> void:
	get_tree().paused = false


func is_running() -> bool:
	return _running


func _drain() -> void:
	_running = true
	GameState.set_event()
	pause_tree()

	while not _queue.is_empty():
		await _run(_queue.pop_front())

	_running = false
	run_tree()
	GameState.set_idle()
	ConversationBus.event_concluded.emit()


func _run(request: EventRequest) -> void:
	choices = []
	subject = request.subject

	var steps: Array[EventStep] = []
	var completion_id := ""
	var data: Variant = request.data

	if data is String:
		if not RunState.current.flags.is_event_completed(data):
			var ev := EventRegistry.get_event(data)
			if ev == null:
				push_warning("Unknown event id: %s" % data)
			else:
				steps = ev.steps
				completion_id = data
	elif data is EventResource:
		steps = (data as EventResource).steps
		completion_id = (data as EventResource).id
	elif data is Array:
		steps = _coerce_step_array(data)
	else:
		push_warning("Event has an incorrect type: %s" % data)

	for step in steps:
		if step == null:
			push_error("Null step in event")
			continue

		if not step.should_run(self):
			continue

		await step.run(self)

	if completion_id != "":
		RunState.current.flags.mark_event_completed(completion_id)

	subject = null
	request.complete()


func _coerce_step_array(arr: Array) -> Array[EventStep]:
	var typed: Array[EventStep] = []
	for s in arr:
		if s is EventStep:
			typed.append(s)
		else:
			push_error("Event step is not an EventStep resource: %s" % s)
	return typed
