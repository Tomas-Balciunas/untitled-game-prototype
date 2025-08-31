extends Resource

class_name Skill

@export var name: String
@export var description: String
#@export var icon: Texture2D
@export var mp_cost: int = 0
@export var sp_cost: int = 0
@export var modifier: float = 0
@export var effects: Array[Effect] = []
@export var damage_type: DamageTypes.Type
@export var targeting_type: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE
## only matters when bounce targeting is selected
@export var bounce_instances: int = 0


func _get_name() -> String:
	return name
	
func get_description() -> String:
	return description
