extends PassiveEffect
class_name GuardEffect

func listened_triggers() -> Array:
	return [EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner_is_target(event)

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	if !event is DamageInstance:
		return
	
	var reduction: float = (event as DamageInstance).calculator.damage_reduction
	var computed: float = maxf(0.0, reduction * 0.5)
	(event as DamageInstance).calculator.damage_reduction = computed
