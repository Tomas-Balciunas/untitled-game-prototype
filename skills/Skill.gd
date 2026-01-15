extends Resource

class_name Skill

@export var id: String
@export var name: String
@export var description: String
#@export var icon: Texture2D
@export var mp_cost: int = 0
@export var sp_cost: int = 0
@export var effects: Array[Effect] = []
@export var targeting_type: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE
@export var owner_only: bool = false

var final_mp_cost: int = 0
var final_sp_cost: int = 0

func _get_name() -> String:
	return name
	
func get_description() -> String:
	return description

func build_context(_source: SkillSource, _target: CharacterInstance) -> ActionContext:
	return

func get_resolver() -> EffectResolver:
	return

func can_select(c: CharacterInstance) -> bool:
	return final_mp_cost <= c.state.current_mana and final_sp_cost <= c.state.current_sp

func can_use(c: CharacterInstance) -> bool:
	return final_mp_cost <= c.state.current_mana and final_sp_cost <= c.state.current_sp

func set_cost(c: CharacterInstance) -> void:
	final_mp_cost = mp_cost
	final_sp_cost = sp_cost
	
	for e: Effect in c.effects:
		if e._modifies_skill_cost():
			e.modify_skill_cost(self)
