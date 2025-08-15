extends Effect
class_name PoisonEffect

@export var damage_per_turn: int = 5

var _remaining := 0
var _source: CharacterInstance

func on_apply(new_owner: CharacterInstance) -> void:
	_remaining = duration_turns
	self.owner = new_owner
	BattleTextLines.print_line("Poison applied to %s for %d turns" %
		[owner.resource.name, duration_turns])

func on_trigger(trigger: String, ctx: ActionContext) -> void:
	if trigger == EffectTriggers.ON_POST_HIT:
		_source = ctx.source
		ctx.target.apply_effect(self, ctx, func(inst: Effect):
			inst.owner = ctx.target
			inst._source = _source
			inst._remaining = duration_turns
		)

	if trigger == EffectTriggers.ON_TURN_END and _remaining > 0:
		if owner == null:
			push_error("PoisonEffect: Owner is null during on_turn_end tick.")
			return

		var tick = AttackAction.new()
		tick.attacker = _source
		tick.defender = owner
		tick.type = DamageTypes.Type.POISON
		tick.base_value = damage_per_turn
		tick.options["dot"] = true 
		DamageResolver.apply_attack(tick)
		
		_remaining -= 1
		print("Remaining poison turns for %s applied by %s: %s" % [owner.resource.name, _source.resource.name, _remaining])
		if _remaining <= 0:
			print("[PoisonEffect] Poison expired on %s." % owner.resource.name)
			owner.remove_effect(self)
