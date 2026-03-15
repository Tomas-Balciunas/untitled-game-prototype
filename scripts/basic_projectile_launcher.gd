extends ProjectileLauncher

class_name BasicProjectileLauncher


func _init(_resolver: EffectResolver, _ctx: ActionContext) -> void:
	assert(_resolver)
	assert(_ctx)
	
	resolver = _resolver
	ctx = _ctx
	actor = ctx.source.get_actor()
	actor_slot = BattleContext.get_slot(actor)
	
	assert(actor)
	assert(actor_slot)


func fire(is_active_attack: bool = false) -> void:
	for target in ctx.targets:
		var target_slot: FormationSlot = BattleContext.get_slot(target)
		
		if !target:
			continue
			
		var projectile_ctx: ActionContext = ActionContext.new()
		projectile_ctx.source = ctx.source
		projectile_ctx.targeting_range = TargetingManager.RangeType.RANGED
		projectile_ctx.set_targets(target)
		projectile_ctx.actively_cast = is_active_attack
		
		var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, projectile_ctx, resolver)
		
		orchestrator.execute_action(
			func(e: ActionEvent) -> void:
				actor_slot.body_instance.fire_projectile(e, target_slot.global_position),
			"basic projectile"
		)
