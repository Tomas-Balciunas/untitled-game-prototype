extends Resource
class_name AttackAction

var attacker: CharacterInstance
var defender: CharacterInstance
var type: DamageTypes.Type
var base_value: float = 0
var tags: Array[String] = []
var options: Dictionary = {}
