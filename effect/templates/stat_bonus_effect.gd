extends PassiveEffect
class_name StatBonusEffect

@export var stat: Stats.StatRef = Stats.StatRef.DEFENSE
@export var value: int = 5

var _modifier: StatModifier


func listened_triggers() -> Array:
	return []


func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return false


func on_apply() -> void:
	_modifier = StatModifier.new()
	_modifier.stat = stat
	_modifier.type = StatModifier.Type.ADDITIVE
	_modifier.value = value
	_modifier.name = name
	owner.state.add_modifier(_modifier)
	StatCalculator.recalculate_stat(owner, stat)


func remove_self() -> void:
	if _modifier and owner:
		owner.state.remove_modifier(_modifier)
		StatCalculator.recalculate_stat(owner, stat)
	super.remove_self()
