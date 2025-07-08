extends Resource
class_name AttackAction

var attacker: CharacterInstance
var target: CharacterInstance
var type: String = "physical"
var base_value: int = 0
var is_critical: bool = false
var tags: Array[String] = []
