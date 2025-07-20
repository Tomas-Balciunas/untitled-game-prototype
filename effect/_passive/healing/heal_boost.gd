extends Effect

class_name HealBoost

@export var modifier: float = 0.2

func on_trigger(trigger: String, ctx: ActionContext):
	if trigger == EffectTriggers.ON_HEAL:
		if ctx is HealingContext:
			ctx.final_value += ctx.final_value * modifier
