extends Resource
class_name AttackAction

var attacker: CharacterInstance
var defender: CharacterInstance
var type: DamageTypes.Type
var base_value: float = 0
var effects: Array[Effect] = []
var options: Dictionary = {}
var actively_cast: bool = false
