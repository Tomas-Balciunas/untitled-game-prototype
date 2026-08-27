extends GutTest

const FLAG := "gut_test_event"


func after_each() -> void:
	RunState.current.flags.completed_events.erase(FLAG)


func test_unknown_event_not_completed() -> void:
	assert_false(RunState.current.flags.is_event_completed(FLAG))


func test_mark_and_check() -> void:
	RunState.current.flags.mark_event_completed(FLAG)
	assert_true(RunState.current.flags.is_event_completed(FLAG))
