extends Effect
class_name DamageShare

@export var share_percent: float = 0.10

func register_signals() -> void:
	_bind(BattleEventBus, "damage_about_to_be_applied", "_on_ally_damaged")

func _on_ally_damaged(ctx: DamageContext) -> void:
	var damaged = ctx.target
	
	if damaged != owner and not owner.is_dead and ctx.manager.same_side(damaged, owner):
		var transfer = ceil(ctx.final_value * share_percent)
		var final = floor(ctx.final_value - transfer)
		ctx.final_value = final
		owner.set_current_health(owner.stats.current_health - transfer)
		BattleTextLines.print_line(
			"%s absorbs %d damage for %s!" %
			[owner.resource.name, transfer, damaged.resource.name]
		)
