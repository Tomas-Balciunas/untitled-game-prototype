extends Effect
class_name ArmorPierce

@export var ignore_percent: float = 0.5

func on_trigger(trigger: String, ctx: ActionContext) -> void:
	if trigger == EffectTriggers.ON_HIT:
		ctx.set_meta("ignore_defense_percent", ignore_percent)
