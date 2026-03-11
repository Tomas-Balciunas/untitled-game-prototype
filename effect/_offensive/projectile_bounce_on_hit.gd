extends PassiveEffect

class_name ProjectileBounceOnHit

@export var bounces: int = 5


func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	if !BattleContext.in_battle:
		return false
	
	return event.ctx.source.get_actor() == owner and event.ctx.actively_cast == true


func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	if !_event is DamageInstance:
		return
	
	var event: DamageInstance = _event as DamageInstance
	
	var initial_target: CharacterInstance = event.ctx.initial_target
	var is_ally: bool = PartyManager.has_member(initial_target.resource.id)
	var initial_target_slot: FormationSlot = BattleContext.get_slot(initial_target, is_ally)
	var actor: CharacterInstance = event.ctx.source.get_actor()
	
	if !initial_target or !actor is CharacterInstance:
		return
	
	var slots: Array[FormationSlot] = BattleContext.get_valid_slots(is_ally)
	
	var previous_target: FormationSlot = initial_target_slot

	for i in range(bounces):
		var target: FormationSlot = get_valid_slot(previous_target, slots)
		
		if !target:
			continue
		
		var bounce_ctx: ActionContext = ActionContext.new()
		bounce_ctx.source = event.ctx.source
		bounce_ctx.targeting_range = TargetingManager.RangeType.RANGED
		bounce_ctx.set_targets(target.character_instance)
		
		var resolver: DamageResolver = DamageResolver.new(8)
		
		var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, bounce_ctx, resolver)
		await orchestrator.execute_action(
			func(e: ActionEvent) -> void:
				previous_target.body_instance.bounce_projectile(e, previous_target.global_position, target.global_position)
		)
		
		previous_target = target
	
	
func get_valid_slot(exclude: FormationSlot, slots: Array[FormationSlot]) -> FormationSlot:
	var candidates: Array[FormationSlot] = []
	
	for s in slots:
		if valid_slot(s, exclude):
			candidates.append(s)
	
	if candidates.is_empty():
		return null
	
	return candidates.pick_random()
	
	
func valid_slot(slot: FormationSlot, exclude: FormationSlot) -> bool:
	if !slot.is_slot_targeting_enabled or slot == exclude:
		return false
	
	return true
	
	
	
	
