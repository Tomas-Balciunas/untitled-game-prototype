extends ProjectileLauncher

class_name SalvoProjectileLauncher


func _init(_resolver: EffectResolver, _ctx: ActionContext) -> void:
	assert(_resolver)
	assert(_ctx)
	
	resolver = _resolver
	ctx = _ctx
	initial_target = ctx.initial_target
	is_ally = PartyManager.has_member(initial_target.resource.id)
	initial_target_slot = BattleContext.get_slot(initial_target, is_ally)
	actor = ctx.source.get_actor()
	
	assert(initial_target)
	assert(initial_target_slot)
	assert(actor)
	assert(actor_slot)


func shrapnel(pellets: int, is_active_attack: bool = false) -> void:
	var slots: Array[FormationSlot] = BattleContext.get_valid_slots(is_ally)
	
	for i in range(pellets):
		var target: FormationSlot = slots.pick_random()
		
		var bounce_ctx: ActionContext = ActionContext.new()
		bounce_ctx.source = ctx.source
		bounce_ctx.targeting_range = TargetingManager.RangeType.RANGED
		bounce_ctx.set_targets(target.character_instance)
		bounce_ctx.actively_cast = is_active_attack
		bounce_ctx.options = {
			"pellet": i
		}
		
		var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, bounce_ctx, resolver)
		orchestrator.execute_action(
			func(e: ActionEvent) -> void:
				actor_slot.body_instance.fire_projectile(e, target.global_position),
			"bounce %s" % i
		)


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
