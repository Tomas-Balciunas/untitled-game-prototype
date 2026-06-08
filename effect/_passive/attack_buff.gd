extends BuffEffect

class_name AttackBuff

@export var modifier: StatModifier
@export var value: int = 10


func on_apply() -> void:
	if !modifier:
		var mod := StatModifier.new()
		mod.name = "Attack++"
		mod.description = "Increases attack power"
		mod.type = StatModifier.Type.ADDITIVE
		mod.value = value

		modifier = mod

	owner.state.add_temporary_modifier(modifier)
	StatCalculator.recalculate_stat(owner, modifier.stat)
	BattleTextLines.print_line("applied att buff to %s" % owner.resource.name)

## Duration is handled by the base lifecycle (counts down at expire_phase,
## TURN_END by default). We only need to undo the stat modifier on expiry.
func on_expire() -> void:
	if owner and modifier:
		owner.state.remove_temporary_modifier(modifier)
		StatCalculator.recalculate_stat(owner, modifier.stat)
	super()

func listened_triggers() -> Array:
	return []

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return false
