extends Node

class_name ActionOrchestrator


var ctx: ActionContext = null
var resolver: EffectResolver = null


func _init(_performer: CharacterInstance, _ctx: ActionContext, _resolver: EffectResolver) -> void:
	ctx = _ctx
	resolver = _resolver


func execute_action(animation_callable: Callable, info: String = "") -> void:
	var event := ActionEvent.new(info)
	BattleContext.new_action(event)

	animation_callable.call(event)

	if !event.confirmed:
		await event.confirmed_signal
	
	resolver.execute(ctx)
	event.finish()
