extends ProjectileLauncher

class_name BounceProjectileLauncher


func _init(_resolver: EffectResolver, _ctx: ActionContext) -> void:
	assert(_resolver)
	assert(_ctx)
	
	resolver = _resolver
	ctx = _ctx
	initial_target = ctx.initial_target
	is_ally = PartyManager.has_member(initial_target.resource.id)
	initial_target_slot = BattleContext.get_slot(initial_target)
	actor = ctx.source.get_actor()
	actor_slot = BattleContext.get_slot(actor)
	
	assert(initial_target)
	assert(initial_target_slot)
	assert(actor)
	assert(actor_slot)


func bounce(bounces: int, is_active_attack: bool = false, start_from_target: bool = true) -> void:
	var slots: Array[FormationSlot] = BattleContext.get_valid_slots(is_ally)
	
	var previous_target: FormationSlot = null
	
	if start_from_target:
		previous_target = initial_target_slot
	else:
		previous_target = actor_slot
	
	var action_event := ActionEvent.new("bounce parent")
	BattleContext.new_action(action_event)
	
	for i in range(bounces):
		if !previous_target:
			continue
		
		var target: FormationSlot = get_valid_slot(previous_target, slots)
		
		if i <= 0 and start_from_target == false:
			target = initial_target_slot
		
		if !target:
			continue
		
		var bounce_ctx: ActionContext = ActionContext.new()
		bounce_ctx.source = ctx.source
		bounce_ctx.targeting_range = TargetingManager.RangeType.RANGED
		bounce_ctx.set_targets(target.character_instance)
		bounce_ctx.actively_cast = is_active_attack
		bounce_ctx.options = {
			"total_bounces": bounces,
			"current_bounce": i + 1
		}
		
		var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, bounce_ctx, resolver)
		await orchestrator.execute_action(
			func(e: ActionEvent) -> void:
				previous_target.body_instance.fire_projectile(e, target.global_position, previous_target.global_position),
			"bounce %s" % i
		)
		
		previous_target = target
	
	action_event.finish()
	

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
