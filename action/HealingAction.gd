extends Resource
class_name HealingAction

var provider: CharacterInstance
var receiver: CharacterInstance
var base_value: int
var effects: Array[Effect]
var options: Dictionary = {}
var actively_cast: bool = false
