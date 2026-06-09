extends RefCounted
class_name TriggerEvent

var source: ContextSource
var target: Character
var ctx: ActionContext

func from_base_event(event: TriggerEvent) -> void:
	source = event.source
	target = event.target
	ctx = event.ctx
