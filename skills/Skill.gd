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


func _get_name() -> String:
	return name
	
func get_description() -> String:
	return description

func build_context(_source: SkillSource, _target: CharacterInstance) -> ActionContext:
	return

func get_resolver() -> EffectResolver:
	return
