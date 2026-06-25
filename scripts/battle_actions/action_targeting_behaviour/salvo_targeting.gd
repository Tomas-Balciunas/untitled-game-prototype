extends BaseLauncher

class_name SalvoLauncher


func _init(_resolver: EffectResolver, _ctx: ActionContext) -> void:
	assert(_resolver)
	assert(_ctx)
	
	resolver = _resolver
	ctx = _ctx
	initial_target = ctx.initial_target
	is_ally = PartyManager.has_member(initial_target.resource.id)
	actor = ctx.source.get_actor()
	
	assert(initial_target)
	assert(actor)


func shrapnel(pellets: int, is_active_attack: bool = false) -> void:
	var slots: Array[Character] = BattleContext.get_valid_battlers(is_ally)
	
	for i in range(pellets):
		var target: Character = slots.pick_random()
		
		var bounce_ctx: ActionContext = ActionContext.new()
		bounce_ctx.source = ctx.source
		bounce_ctx.set_targets(target)
		bounce_ctx.actively_cast = is_active_attack
		bounce_ctx.options = {
			"pellet": i
		}
		
		var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, bounce_ctx, resolver)
		orchestrator.execute_action(
			func(e: ActionEvent) -> void:
				e.confirm(),
			"bounce %s" % i
		)


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
