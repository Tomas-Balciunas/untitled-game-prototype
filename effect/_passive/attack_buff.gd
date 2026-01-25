extends BuffEffect

class_name AttackBuff

@export var modifier: StatModifier
@export var value: int = 10

var remaining_turns: int


func on_apply() -> void:
	if !modifier:
		var mod := StatModifier.new()
		mod.name = "Attack++"
		mod.description = "Increases attack power"
		mod.type = StatModifier.Type.ADDITIVE
		mod.value = value
		
		modifier = mod
	
	owner.state.add_temporary_modifier(modifier)
	remaining_turns = duration_turns
	StatCalculator.recalculate_stat(owner, modifier.stat)
	BattleTextLines.print_line("applied att buff to %s" % owner.resource.name)
	
func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_END]
	
func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return owner == _event.actor.get_actor()

func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	remaining_turns -= 1
	
	if remaining_turns <= 0:
		owner.stats.remove_temporary_modifier(modifier)
		owner.remove_effect(self)
