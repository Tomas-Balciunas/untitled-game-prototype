extends Node
class_name HealingManager

signal healing_resolved(ctx: HealingContext)

func apply_heal(action: HealingAction, battle_manager: BattleManager) -> HealingContext:
	return _apply_core(
		action.provider,
		action.receiver,
		action.base_value,
		battle_manager,
		action.options,
	)

func _apply_core(source: CharacterInstance, target: CharacterInstance, base: float, battle_manager: BattleManager, options: Dictionary = {}) -> HealingContext:
	var ctx = HealingContext.new()
	ctx.source    = source
	ctx.target    = target
	ctx.base_value  = base
	ctx.final_value = base
	ctx.options = options
	ctx.manager = battle_manager
	
	source.process_effects(EffectTriggers.ON_HEAL, ctx)
	
	target.process_effects(EffectTriggers.ON_RECEIVE_HEAL, ctx)

	target.set_current_health(target.stats.current_health + ctx.final_value)

	BattleTextLines.print_line("%s healed %s for %d" % [ctx.source.resource.name, ctx.target.resource.name, ctx.final_value])
	emit_signal("healing_resolved", ctx)

	return ctx
