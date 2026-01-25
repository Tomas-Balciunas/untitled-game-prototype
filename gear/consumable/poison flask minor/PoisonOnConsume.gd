extends StatusEffect
class_name PoisonOnConsume

@export var damage_per_turn: int = 10

func listened_triggers() -> Array:
	return [EffectTriggers.ON_USE_CONSUMABLE]
	
func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event.actor == owner

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var poison: PoisonEffect = PoisonEffect.new()
	poison.duration_turns = duration_turns
	poison.damage_per_turn = damage_per_turn
	poison._source = event.actor
	poison._is_instance = true
	var app := EffectApplicationContext.new()
	app.source = event.actor
	app.target = event.ctx.target
	app.effect = poison
	EffectApplicationResolver.new().execute(app)

func get_description() -> String:
	return "Applies poison on the target for %s turns dealing %s damage per turn" % [duration_turns, damage_per_turn]
