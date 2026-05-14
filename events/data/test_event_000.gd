class_name TestEvent000


static func build() -> EventResource:
	var ev := EventResource.new()
	ev.id = "test_event_000"

	var steps: Array[EventStep] = [
		DialogueStep.say("Unknown Entity", ["Abandon all hope", "Ye who enter here"]),
		DialogueStep.say("Someone Else", ["Test"]),
		DialogueStep.say("Unknown Entity", ["Whatever"]),
		EncounterStep.against("arena_default_00", ["e_enemy_002", "0000"]),
		DialogueStep.say("Unknown Entity", ["Well done", "You may pass"]),
	]
	ev.steps = steps
	return ev
