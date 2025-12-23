extends StatusEffect
class_name PoisonEffect

var damage_per_turn: int = 5
var stacks: int = 1
var _remaining: int = 0
var _should_refresh_duration: bool = true

func _init() -> void:
	category = EffectCategory.DEBUFF

func _is_stackable() -> bool:
	return true

	
func can_process(event: TriggerEvent) -> bool:
	return event.actor.character == owner

func on_apply() -> void:
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


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_END]

func on_trigger(_event: TriggerEvent) -> void:
	if _remaining <= 0:
		return
	if owner == null:
		push_error("PoisonEffect: Owner is null during on_turn_end tick.")
		return
	var tick := DamageContext.new(damage_per_turn * stacks)
	tick.source = source
	tick.target = owner
	tick.type = DamageTypes.Type.POISON
	tick.options = tick.options.duplicate() if tick.options else {}
	DamageResolver.new().execute(tick)

	_remaining -= 1
	print("Poison tick: %s takes %d from %s — remaining %d" % [owner.resource.name, damage_per_turn, tick.source.get_source_name(), _remaining])

	if _remaining <= 0:
		print("Poison expired on %s" % owner.resource.name)
		on_expire()

func _get_name() -> String:
	return "Poison"
	
func get_description() -> String:
	return "Deals %s damage per turn, %s turns remaining" % [damage_per_turn * stacks, _remaining]
