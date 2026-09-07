extends EffectResolver

class_name TurnStageResolver

var stage: String
var actor: Character = null


func _init(_stage: String, _actor: Character) -> void:
	stage = _stage
	actor = _actor


func execute(ctx: ActionContext) -> ActionContext:
	var event: TriggerEvent = build_event(ctx)
	
	EffectRunner.process_trigger(stage, event)

	return event.ctx

func execute_turn_start(ctx: ActionContext) -> TurnStateEvent:
	var event: TurnStateEvent = build_turn_start_event(ctx)
	
	EffectRunner.process_trigger(stage, event)

	return event

func build_event(ctx: ActionContext) -> TriggerEvent:
	var event: TriggerEvent = TriggerEvent.new()
	event.ctx = ctx
	event.source = CharacterSource.new(actor)
	
	return event

func build_turn_start_event(ctx: ActionContext) -> TurnStateEvent:
	var event: TurnStateEvent = TurnStateEvent.new(TurnOptions.new(actor))
	event.ctx = ctx
	event.source = CharacterSource.new(actor)
	
	return event
