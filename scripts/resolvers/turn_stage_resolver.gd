extends EffectResolver

class_name TurnStageResolver

var stage: String
var actor: CharacterInstance = null


func _init(_stage: String, _actor: CharacterInstance) -> void:
	stage = _stage
	actor = _actor


func execute(ctx: ActionContext) -> ActionContext:
	var event = build_event(ctx)
	
	EffectRunner.process_trigger(stage, event)
	
	if event.ctx.should_tick:
		var ticker = TickDoT.new(actor)
		ticker.execute()

	return event.ctx

func build_event(ctx: ActionContext) -> TriggerEvent:
	var event = TriggerEvent.new()
	event.ctx = ctx
	event.actor = CharacterSource.new(actor)
	
	return event
