extends RefCounted
class_name TriggerEvent

var source: ContextSource
var target: Character
var ctx: ActionContext
var target_was_dead: bool = false

func from_base_event(event: TriggerEvent) -> void:
	source = event.source
	target = event.target
	ctx = event.ctx
	target_was_dead = event.target_was_dead

func from_context(context: ActionContext) -> void:
	source = context.source
	target = context.initial_target
	ctx = context
	target_was_dead = target != null and target.is_dead
