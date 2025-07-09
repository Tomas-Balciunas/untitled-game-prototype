extends Effect
class_name PoisonEffect

@export var damage_per_turn: int = 5
@export var duration_turns: int = 3

var _remaining := 0
var _source: CharacterInstance

func on_apply(new_owner: CharacterInstance) -> void:
	_remaining = duration_turns
	self.owner = new_owner
	print("[PoisonEffect] Applied to %s for %d turns, %d damage per turn." %
		[owner.resource.name, duration_turns, damage_per_turn])

func on_trigger(trigger: String, data) -> void:
	if trigger == "on_post_hit":
		_source = data.attacker
		var duplicate_effect = self.duplicate()
		duplicate_effect.owner = data.defender
		duplicate_effect._source = _source
		duplicate_effect._remaining = duration_turns
		print("[PoisonEffect] Ticking on %s (%d damage), %d turns remaining." %
			[duplicate_effect.owner.resource.name, damage_per_turn, duplicate_effect._remaining])
		data.defender.apply_effect(duplicate_effect)

	if trigger == "on_turn_end" and _remaining > 0:
		if owner == null:
			push_warning("PoisonEffect: Owner is null during on_turn_end tick.")
			return

		var tick = AttackAction.new()
		tick.attacker = _source
		tick.defender = owner
		tick.type = DamageTypes.Type.POISON
		tick.base_value = damage_per_turn
		DamageResolver.apply_attack(tick)
		
		_remaining -= 1
		if _remaining <= 0:
			print("[PoisonEffect] Poison expired on %s." % owner.resource.name)
			owner.remove_effect(self)
