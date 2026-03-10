extends Node

class_name ActionOrchestrator


var performer: CharacterInstance = null
var ctx: ActionContext = null
var resolver: EffectResolver = null


func _init(_performer: CharacterInstance, _ctx: ActionContext, _resolver: EffectResolver) -> void:
	performer = _performer
	ctx = _ctx
	resolver = _resolver



func execute_action(animation_callable: Callable) -> void:
	var event := ActionEvent.new()

	animation_callable.call(event)

	if !event.confirmed:
		#var timed_out: bool = await SignalFailsafe.await_signal_or_timeout(self, event.confirmed_signal, 1.0)
		#if timed_out:
					#push_error("Attack connected signal timed out for character: %s, %s " % [performer.resource.name, performer.resource.id])
		await event.confirmed_signal
	
	resolver.execute(ctx)
