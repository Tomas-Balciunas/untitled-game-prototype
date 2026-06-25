extends ProjectileLauncher

class_name BounceLauncher


func _init(_resolver: EffectResolver, _ctx: ActionContext) -> void:
	assert(_resolver)
	assert(_ctx)
	
	resolver = _resolver
	ctx = _ctx
	initial_target = ctx.initial_target
	is_ally = PartyManager.has_member(initial_target.resource.id)
	actor = ctx.source.get_actor()
	actor_slot = BattleContext.get_slot(actor)
	
	assert(initial_target)
	assert(actor)
	assert(actor_slot)


func bounce(bounces: int, is_active_attack: bool = false) -> void:
	var slots: Array[Character] = BattleContext.get_valid_battlers(is_ally)
	
	var previous_target: Character = initial_target
	
	var action_event := ActionEvent.new("bounce parent")
	BattleContext.new_action(action_event)
	
	for i in range(bounces):
		if !previous_target:
			continue
		
		var target: Character = null
		
		if i <= 0:
			target = initial_target
		else:
			target = get_valid_slot(previous_target, slots)
		
		if !target:
			continue
		
		var bounce_ctx: ActionContext = ActionContext.new()
		bounce_ctx.source = ctx.source
		bounce_ctx.set_targets(target)
		bounce_ctx.actively_cast = is_active_attack
		bounce_ctx.options = {
			"total_bounces": bounces,
			"current_bounce": i + 1
		}
		
		var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, bounce_ctx, resolver)
		await orchestrator.execute_action(
			func(e: ActionEvent) -> void:
				e.confirm(),
			"bounce %s" % i
		)
		
		previous_target = target
		await BattleContext.wait(0.1)
	
	action_event.finish()
	

func get_valid_slot(exclude: Character, slots: Array[Character]) -> Character:
	var candidates: Array[Character] = []
	
	for s in slots:
		if valid_slot(s, exclude):
			candidates.append(s)
	
	if candidates.is_empty():
		return null
	
	return candidates.pick_random()
	
	
func valid_slot(slot: Character, exclude: Character) -> bool:
	if slot.is_dead or slot == exclude:
		return false
	
	return true
