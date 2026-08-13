extends PassiveEffect

class_name BleedOnHit

@export var stacks: int = 30

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	if !event.ctx.actively_cast:
		return false
	
	if event.source.get_actor() != owner:
		return false
		
	
	return event.target != null

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var bleed: Bleed = Bleed.new()
	bleed.stacks = stacks
	
	var ctx: ActionContext = event.ctx.duplicate()
	ctx.set_targets(event.target)
	ctx.source = EffectSource.new(bleed)
	
	var resolver: EffectApplicationResolver = EffectApplicationResolver.new(bleed)
	resolver.execute(ctx)
