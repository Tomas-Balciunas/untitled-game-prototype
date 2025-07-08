extends Resource
class_name DamageContext

var attacker: CharacterInstance
var defender: CharacterInstance

var type: DamageTypes.Type
var base_value: int
var is_critical: bool = false
var final_value: int
var tags: Array[Effect] = []
