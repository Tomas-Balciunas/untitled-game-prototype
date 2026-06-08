extends StatusEffect

class_name Bleed

@export var stacks: int = 0
## default amount of stacks lost on turn end 
@export var stack_loss: float = 0.5
@export var damage_per_stack: float = 0.2

func _init() -> void:
	battle_only = true
	expires_after_battle = true
	show_in_status = true
	native = false

func listened_triggers() -> Array:
	return [
		EffectTriggers.ON_TURN_END,
		EffectTriggers.ON_DAMAGE_APPLIED
	]
	
func can_process(stage: String, event: TriggerEvent) -> bool:
	match stage:
		EffectTriggers.ON_DAMAGE_APPLIED:
			if event is not DamageInstance:
				push_error("on damage applied received wrong event")
				
				return false
			
			var dmg_inst: DamageInstance = event as DamageInstance
			
			return dmg_inst.target == owner and event.ctx.actively_cast == true
		EffectTriggers.ON_TURN_END:
			return event.source.get_actor() == owner
		_:
			return false
	
func on_apply() -> void:
	pass
	
func on_trigger(stage: String, event: TriggerEvent) -> void:
	if stage == EffectTriggers.ON_DAMAGE_APPLIED:
		var ctx: ActionContext = ActionContext.new()
		ctx.set_targets(owner)
		ctx.source = event.source
		ctx.targeting_range = event.ctx.targeting_range
		var resolver = DamageResolver.new(stacks * damage_per_stack)
		resolver.execute(ctx)
	
	if stage == EffectTriggers.ON_TURN_END:
		stacks = roundi(stacks * stack_loss)
		

func get_display_stacks() -> int:
	return stacks

func _get_name() -> String:
	return "Bleed"

func get_description() -> String:
	return "Bleed status"
