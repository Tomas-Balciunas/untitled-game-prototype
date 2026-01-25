extends DebuffEffect
class_name PoisonOnHit

var damage_per_turn: int = 5

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]
	
func can_process(_stage: String, event: TriggerEvent) -> bool:
	match event.actor:
		TrapSource:
			return true
	
	return event.actor.get_actor() == owner and event.ctx.actively_cast

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var poison: PoisonEffect = PoisonEffect.new()
	poison.duration_turns = duration_turns
	poison.damage_per_turn = damage_per_turn
	poison.source = event.actor
	var app := EffectApplicationContext.new()
	app.source = event.actor
	app.target = event.ctx.target
	app.effect = poison
	EffectApplicationResolver.new().execute(app)

func get_description() -> String:
	return "Applies poison on the target for %s turns dealing %s damage per turn" % [duration_turns, damage_per_turn]
