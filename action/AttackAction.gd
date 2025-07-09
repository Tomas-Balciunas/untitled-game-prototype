extends Resource
class_name AttackAction

var attacker: CharacterInstance
var defender: CharacterInstance
var type: DamageTypes.Type
var base_value: int = 0
var is_critical: bool = false
var tags: Array[String] = []
