extends PassiveEffect

class_name ProjectileBounceOnHit

@export var bounces: int = 5


func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event.ctx.source.get_actor() == owner and event.ctx.actively_cast == true


func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	if !_event is DamageInstance:
		return
	
	var event: DamageInstance = _event as DamageInstance
	
	var slots: Array[FormationSlot] = BattleContext.get_slots_enemies()
	slots = slots.filter(func (s: FormationSlot) -> bool: return s.is_slot_targeting_enabled == true)
	
	if len(slots) < 2:
		return
	
	slots.shuffle()
	
	var initial_target: CharacterInstance = event.ctx.initial_target
	var actor: CharacterInstance = event.ctx.source.get_actor()
	
	if !actor is CharacterInstance:
		return
	
	var targets: Array[FormationSlot]
	
	var last_target: FormationSlot = null
	
	for i in range(bounces):
		var t: FormationSlot
		
		if i == 0:
			t = slots.filter(
				func (s: FormationSlot) -> bool: return s.character_instance != initial_target
				).pick_random()
		elif last_target:
			t = slots.filter(
				func (s: FormationSlot) -> bool: return last_target != s
				).pick_random()
		else:
			t = slots.pick_random()
		
		if t:
			targets.append(t)
			last_target = t
			BattleContext.new_action()
			
	
	var initial_target_slot: FormationSlot = BattleContext.enemy_formation.get_slot_for(initial_target)
	var previous_target: FormationSlot = initial_target_slot

	for target: FormationSlot in targets:
		if !target:
			BattleContext.end_action()
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
