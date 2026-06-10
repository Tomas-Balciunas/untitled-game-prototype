extends StatusEffect

class_name Bleed

const ON_BLEED_CONSUME = "on_bleed_consume"
const ON_BLEED_DAMAGE_INSTANCE = "on_bleed_damage_instance"

@export var stacks: int = 0
## default amount of stacks lost on turn end 
@export var stack_loss: float = 0.5
@export var damage_per_stack: float = 0.2

@export var turn_end_priority: int = -900
@export var damage_applied_priority: int = -1010

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
			
			return owner_is_target(event) and event.ctx.actively_cast == true
		EffectTriggers.ON_TURN_END:
			return owner_is_actor(event)
		_:
			return false
	
func on_trigger(stage: String, event: TriggerEvent) -> void:
	if stage == EffectTriggers.ON_DAMAGE_APPLIED:
		var bleed_event: BleedEvent = BleedEvent.new()
		bleed_event.from_bleed(self)
		bleed_event.from_base_event(event)
		
		var ctx: ActionContext = ActionContext.new()
		ctx.set_targets(owner)
		ctx.source = event.source
		ctx.targeting_range = event.ctx.targeting_range
		
		EffectRunner.process_trigger(ON_BLEED_DAMAGE_INSTANCE, bleed_event)
		
		var resolver: DamageResolver = DamageResolver.new(roundi(stacks * bleed_event.damage_per_stack))
		resolver.execute(ctx)
	
	if stage == EffectTriggers.ON_TURN_END:
		var bleed_event: BleedEvent = BleedEvent.new()
		bleed_event.from_base_event(event)
		bleed_event.from_bleed(self)
		
		EffectRunner.process_trigger(ON_BLEED_CONSUME, bleed_event)
		
		consume_stacks(bleed_event)

func consume_stacks(bleed_event: BleedEvent) -> void:
	stacks = roundi(stacks * bleed_event.stack_loss)
	
	if stacks <= 0:
		on_expire()

func get_display_stacks() -> int:
	return stacks

func _get_name() -> String:
	return "Bleed"

func get_description() -> String:
	return "Bleed status"

func get_priority(stage: String = "") -> int:
	match stage:
		EffectTriggers.ON_TURN_END:
			return turn_end_priority
		EffectTriggers.ON_DAMAGE_APPLIED:
			return damage_applied_priority
		_:
			return 200

static func is_affected_by_bleed(target: Character) -> bool:
	for effect: Effect in target.effects:
		if effect is Bleed:
			return true
	
	return false
