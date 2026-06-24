extends RefCounted
class_name TriggerEvent

var source: ContextSource
var target: Character
var ctx: ActionContext

func from_base_event(event: TriggerEvent) -> void:
	source = event.source
	target = event.target
	ctx = event.ctx

func from_context(context: ActionContext) -> void:
	source = context.source
	target = context.initial_target
	ctx = context
