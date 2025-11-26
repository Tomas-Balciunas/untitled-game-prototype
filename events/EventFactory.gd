extends Node
class_name EventFactory

static func create_step(data: Dictionary) -> EventStep:
	match data["type"]:
		"text":
			return DialogueStep.new(data)
		"encounter":
			return EncounterStep.new(data)
		"trap":
			return TrapStep.new(data)
		"choice":
			return ChoiceStep.new(data)
		_:
			push_error("Unknown event step type: %s" % data["type"])
			return null
