extends GutTest

const FLAG := "gut_test_event"


func after_each() -> void:
	EventFlags.completed_events.erase(FLAG)


func test_unknown_event_not_completed() -> void:
	assert_false(EventFlags.is_event_completed(FLAG))


func test_mark_and_check() -> void:
	EventFlags.mark_event_completed(FLAG)
	assert_true(EventFlags.is_event_completed(FLAG))
