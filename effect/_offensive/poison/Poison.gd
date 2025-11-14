extends Effect
class_name PoisonEffect

var damage_per_turn: int = 5
var stacks: int = 1
var _remaining: int = 0
var _source: CharacterInstance = null
var _should_refresh_duration := true

func _init() -> void:
	category = EffectCategory.DEBUFF

func _is_stackable() -> bool:
	return true

func set_source(source: CharacterInstance) -> void:
	_source = source
	
func can_process(event: TriggerEvent) -> bool:
	if not _is_runtime_instance:
		return false
	return event.actor == owner

func on_apply(new_owner: CharacterInstance) -> void:
	_is_runtime_instance = true
	owner = new_owner
	_remaining = duration_turns
	# TODO tidy this up
	#for effect in owner.effects:
		#if effect is PoisonEffect:
			#_should_append = false
			#effect.stacks += 1
			#
			#if _should_refresh_duration:
				#effect._remaining = duration_turns
			
	BattleTextLines.print_line("Poison applied to %s for %d turns" % [owner.resource.name, duration_turns])
	_register_if_needed()


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_END]

func on_trigger(event: TriggerEvent) -> void:
	if _is_runtime_instance and event.trigger == EffectTriggers.ON_TURN_END:
		if _remaining <= 0:
			return
		if owner == null:
			push_error("PoisonEffect: Owner is null during on_turn_end tick.")
			return
		var tick := DamageContext.new()
		tick.source = _source
		tick.target = owner
		tick.type = DamageTypes.Type.POISON
		tick.base_value = damage_per_turn * stacks
		tick.final_value = damage_per_turn * stacks
		tick.options = tick.options.duplicate() if tick.options else {}
		DamageResolver.new().execute(tick)

		_remaining -= 1
		print("Poison tick: %s takes %d from %s — remaining %d" % [owner.resource.name, damage_per_turn, tick.source.resource.name, _remaining])

		if _remaining <= 0:
			if owner:
				print("Poison expired on %s" % owner.resource.name)
				owner.remove_effect(self)

func _get_name() -> String:
	return "Poison"
	
func get_description() -> String:
	return "Deals %s damage per turn, %s turns remaining" % [damage_per_turn * stacks, _remaining]
