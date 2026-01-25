extends Resource

class_name Skill

@export var id: String
@export var name: String
@export var description: String
#@export var icon: Texture2D
@export var cost: SkillCost
@export var effects: Array[Effect] = []
@export var targeting_type: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE
@export var owner_only: bool = false


func _get_name() -> String:
	return name
	
func get_description() -> String:
	return description

func get_resolver(_ctx: ActionContext) -> EffectResolver:
	return

func can_select(c: CharacterInstance) -> bool:
	var computed_cost: SkillCost = compute_cost(c)
	
	return computed_cost.get_mana_cost() <= c.state.current_mana and computed_cost.get_sp_cost() <= c.state.current_sp

func can_use(c: CharacterInstance) -> bool:
	return can_select(c)

func compute_cost(c: CharacterInstance) -> SkillCost:
	if !cost:
		cost = SkillCost.new()
		push_error('%s skill is missing cost!' % name)
	
	var sc: SkillCost = cost.duplicate(true)
	
	for e: Effect in c.effects:
		if e._modifies_skill_cost():
			e.modify_skill_cost(self, sc)
	
	return sc
