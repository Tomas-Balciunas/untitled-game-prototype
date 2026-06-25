extends BattleAction
class_name ItemAction


var item: Consumable = null


func _init(_item: Consumable) -> void:
	assert(_item)
	item = _item
	ends_turn = false
	action_point_cost = 1


func build_context(actor: Character, target: Character) -> ActionContext:
	var targeting: TargetingManager.TargetType = item.template.targeting_type
	var targets := TargetingManager.get_applicable_targets(target, targeting)

	var cons := ConsumableContext.new()
	cons.source = ItemSource.new(actor, item)
	cons.set_targets(target, targets)
	cons.temporary_effects = item.get_all_effects()
	cons.actively_cast = true

	return cons


func perform(ctx: ActionContext, actor: Character, attacker_slot: FormationSlot, target_slot: FormationSlot, _event: BattleActionEvent) -> void:
	await attacker_slot.perform_item_use(target_slot)
	var timed_out: bool = await SignalFailsafe.await_signal_or_timeout(
		BattleContext.manager, BattleBus.attack_connected, BattleManager.ATTACK_CONNECTED_TIMEOUT)

	if timed_out:
		push_error("Attack connected signal timed out for character: %s, %s " % [actor.resource.name, actor.resource.id])

	ConsumableResolver.new(item).execute(ctx)
