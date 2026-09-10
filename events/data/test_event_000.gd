class_name TestEvent000


static func build() -> EventResource:
	var ev := EventResource.new()
	ev.id = "test_event_000"
	ev.steps = EventBuilder.new() \
		.say("Someone Else", ["Test"]) \
		.encounter("arena_default_00", ["e_enemy_002", "0000"]) \
		.say("Unknown Entity", ["done"]) \
		.build()
	return ev
