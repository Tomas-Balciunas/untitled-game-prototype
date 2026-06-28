extends BattleAction
class_name ItemAction


var item: Consumable = null


func _init(_item: Consumable) -> void:
	assert(_item)
	item = _item
	ends_turn = false
	action_point_cost = 1


func build_context(actor: Character, target: Character) -> ActionContext:
	var targeting: TargetingManager.TargetType = item.targeting_type if item.targeting_type else TargetingManager.TargetType.SINGLE
	var targets := TargetingManager.get_applicable_targets(target, targeting)

	var cons := ConsumableContext.new()
	cons.source = ItemSource.new(actor, item)
	cons.set_targets(target, targets)
	cons.temporary_effects = item.get_all_effects()
	cons.actively_cast = true

	return cons


func perform(ctx: ActionContext, actor: Character, attacker_slot: FormationSlot, target_slot: FormationSlot, _event: BattleActionEvent) -> void:
	var resolver: ConsumableResolver = ConsumableResolver.new(item)
	var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, ctx, resolver)
	
	await orchestrator.execute_action(
				func(e: ActionEvent) -> void:
					attacker_slot.perform_item_use(e, target_slot),
				"item use",
			)
	
