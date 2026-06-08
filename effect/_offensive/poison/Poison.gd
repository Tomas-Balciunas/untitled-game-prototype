extends DamageOverTimeEffect
class_name PoisonEffect

var stacks: int = 1
var _should_refresh_duration: bool = true


func _init() -> void:
	battle_only = false
	expires_after_battle = false
	resolve_phase = TurnPhase.TURN_END


func _is_stackable() -> bool:
	return true


func on_apply() -> void:
	BattleTextLines.print_line("Poison applied to %s for %d turns" % [owner.resource.name, duration_turns])


func _get_name() -> String:
	return "Poison"


func get_description() -> String:
	return "Deals %s damage per turn, %s turns remaining" % [damage_per_turn * stacks, remaining_turns]


func get_display_stacks() -> int:
	return stacks if stacks > 1 else -1


func _deal_damage(ctx: ActionContext) -> void:
	var tick_ctx: ActionContext = ActionContext.new()
	tick_ctx.source = source
	tick_ctx.set_targets(owner)
	tick_ctx.options = tick_ctx.options.duplicate() if tick_ctx.options else {}
	var resolver = DamageResolver.new((damage_per_turn * stacks) * ctx.tick_power)

	#TODO: play for allies too
	if BattleContext.in_battle:
		var slot = BattleContext.enemy_formation.get_slot_for(owner)
		if slot:
			var orchestrator = ActionOrchestrator.new(owner, tick_ctx, resolver)
			orchestrator.execute_action(
				func (e: ActionEvent) -> void:
					slot.body_instance.play_poison(e),
				"poison"
			)
		else:
			resolver.execute(tick_ctx)
	else:
		resolver.execute(tick_ctx)


func game_save() -> Dictionary:
	var data := super.game_save()
	data["stacks"] = stacks
	return data


func game_load(data: Dictionary) -> void:
	super.game_load(data)
	stacks = data.get("stacks", 1)
