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


func game_load(data: Dictionary) -> void:
	super.game_load(data)
	# on_apply isn't called on load — recreate the modifier so the stat bonus
	# stays applied after restoring from save. Skipped for owner-less templates
	# (e.g. effects stored on gear), since equip_item will run on_apply later.
	if owner:
		_modifier = StatModifier.new()
		_modifier.stat = stat
		_modifier.type = StatModifier.Type.ADDITIVE
		_modifier.value = value
		_modifier.name = name
		owner.state.add_modifier(_modifier)
		StatCalculator.recalculate_stat(owner, stat)
