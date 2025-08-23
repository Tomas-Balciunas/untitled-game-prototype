extends Effect
class_name PoisonEffect

@export var damage_per_turn: int = 5

var _remaining: int = 0
var _source: CharacterInstance = null

func set_source(source: CharacterInstance) -> void:
	_source = source

func on_apply(new_owner: CharacterInstance) -> void:
	_is_runtime_instance = true
	owner = new_owner
	_remaining = duration_turns
	BattleTextLines.print_line("Poison applied to %s for %d turns" % [owner.resource.name, duration_turns])
	_register_if_needed()

func on_expire(_owner: CharacterInstance) -> void:
	_unregister()
	owner = null

func listened_triggers() -> Array:
	if _is_runtime_instance:
		return [EffectTriggers.ON_TURN_END]
	else:
		return [EffectTriggers.ON_DAMAGE_APPLIED, EffectTriggers.ON_USE_CONSUMABLE]

func on_trigger(event: TriggerEvent) -> void:

	if not _is_runtime_instance and event.trigger in listened_triggers():
		var application = EffectApplicationAction.new()
		application.source = event.ctx.source
		application.target = event.ctx.target
		application.effect = self
		EffectApplicationResolver.apply_effect(application)
		return

	if _is_runtime_instance and event.trigger == EffectTriggers.ON_TURN_END:
		if _remaining <= 0:
			return
		if owner == null:
			push_error("PoisonEffect: Owner is null during on_turn_end tick.")
			return
		var tick = AttackAction.new()
		tick.attacker = _source if _source != null else owner
		tick.defender = owner
		tick.type = DamageTypes.Type.POISON
		tick.base_value = damage_per_turn
		tick.options = tick.options.duplicate() if tick.options else {}
		tick.options["dot"] = true
		DamageResolver.apply_attack(tick)

		_remaining -= 1
		print("Poison tick: %s takes %d from %s — remaining %d" % [owner.resource.name, damage_per_turn, tick.attacker.resource.name, _remaining])

		if _remaining <= 0:
			if owner:
				print("Poison expired on %s" % owner.resource.name)
				owner.remove_effect(self)

func get_description() -> String:
	return "Applies poison on the target for %s turns dealing %s damage per turn" % [duration_turns, damage_per_turn]
