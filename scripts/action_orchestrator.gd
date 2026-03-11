extends RefCounted

class_name ActionOrchestrator


var ctx: ActionContext = null
var resolver: EffectResolver = null


func _init(_performer: CharacterInstance, _ctx: ActionContext, _resolver: EffectResolver) -> void:
	ctx = _ctx
	resolver = _resolver



func execute_action(animation_callable: Callable) -> void:
	var event := ActionEvent.new()

	animation_callable.call(event)

	if !event.confirmed:
		print("Waiting for orchestrator impact...")
		await event.confirmed_signal
		print("Projectile finished")
	
	resolver.execute(ctx)
	BattleContext.end_action()
