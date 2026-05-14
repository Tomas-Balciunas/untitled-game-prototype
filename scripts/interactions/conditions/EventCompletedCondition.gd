extends InteractionCondition

class_name EventCompletedCondition


@export var event_id: String = ""
@export var must_be_completed: bool = true


func matches(_c: BaseCharacterResource) -> bool:
	var done := EventFlags.is_event_completed(event_id)
	return done if must_be_completed else not done


static func completed(eid: String) -> EventCompletedCondition:
	var c := EventCompletedCondition.new()
	c.event_id = eid
	c.must_be_completed = true
	return c


static func not_completed(eid: String) -> EventCompletedCondition:
	var c := EventCompletedCondition.new()
	c.event_id = eid
	c.must_be_completed = false
	return c
