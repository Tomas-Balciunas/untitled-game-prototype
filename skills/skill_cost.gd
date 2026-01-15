extends Resource

class_name SkillCost

@export var mana: float = 0.0
@export var sp: float = 0.0


func get_mana_cost() -> int:
	return max(0, round(mana))


func get_sp_cost() -> int:
	return max(0, round(sp))


func consume(source: ContextSource) -> void:
	var caster: CharacterInstance = source.get_actor()
	
	if !caster:
		return
	
	caster.set_current_mana(caster.state.current_mana - get_mana_cost())
	caster.set_current_sp(caster.state.current_sp - get_sp_cost())
