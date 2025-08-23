extends Effect
class_name PoisonOnHit

@export var _chance: float = 1.0

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func on_trigger(event: TriggerEvent) -> void:
	if event.trigger == EffectTriggers.ON_DAMAGE_APPLIED and event.ctx.actively_cast:
		var poison: PoisonEffect = PoisonEffect.new()
		poison.duration_turns = 3
		poison._source = event.ctx.source
		var app = EffectApplicationAction.new()
		app.source = event.ctx.source
		app.target = event.ctx.target
		app.effect = poison
		EffectApplicationResolver.apply_effect(app)
