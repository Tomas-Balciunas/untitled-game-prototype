extends Effect
class_name PoisonOnHit

var damage_per_turn: int = 5

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]
	
func can_process(event: TriggerEvent) -> bool:
	return event.actor == owner and event.ctx.actively_cast

func on_trigger(event: TriggerEvent) -> void:
	var poison: PoisonEffect = PoisonEffect.new()
	poison.duration_turns = duration_turns
	poison.damage_per_turn = damage_per_turn
	poison._source = event.ctx.source
	poison._is_instance = true
	var app := EffectApplicationContext.new()
	app.source = event.ctx.source
	app.target = event.ctx.target
	app.effect = poison
	EffectApplicationResolver.new().execute(app)

func get_description() -> String:
	return "Applies poison on the target for %s turns dealing %s damage per turn" % [duration_turns, damage_per_turn]
