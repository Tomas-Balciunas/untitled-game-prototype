extends Effect

class_name AttackBuff

@export var modifier: StatModifier
@export var value: int = 10

var remaining_turns: int

func _init() -> void:
	is_battle_only = true
	category = EffectCategory.BUFF
	
func on_apply(_owner: CharacterInstance) -> void:
	_is_runtime_instance = true
	_register_if_needed()
	owner = _owner
	
	if !modifier:
		var mod := StatModifier.new()
		mod.name = "Attack++"
		mod.description = "Increases attack power"
		mod.type = StatModifier.Type.ADDITIVE
		mod.value = value
		
		modifier = mod
	
	owner.stats.add_temporary_modifier(modifier)
	remaining_turns = duration_turns
	
func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_END]
	
func can_process(_event: TriggerEvent) -> bool:
	return owner == _event.actor

func on_trigger(_event: TriggerEvent) -> void:
	remaining_turns -= 1
	
	if remaining_turns <= 0:
		owner.stats.remove_temporary_modifier(modifier)
		owner.remove_effect(self)
