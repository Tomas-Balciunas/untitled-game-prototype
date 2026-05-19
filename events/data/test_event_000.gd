class_name TestEvent000


static func build() -> EventResource:
	var ev := EventResource.new()
	ev.id = "test_event_000"
	ev.steps = EventBuilder.new() \
		.say("Unknown Entity", ["Abandon all hope", "Ye who enter here"]) \
		.say("Someone Else", ["Test"]) \
		.say("Unknown Entity", ["Whatever"]) \
		.encounter("arena_default_00", ["e_enemy_002", "0000"]) \
		.say("Unknown Entity", ["Well done", "You may pass"]) \
		.build()
	return ev
