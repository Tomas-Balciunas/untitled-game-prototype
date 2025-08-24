extends Resource
class_name SkillAction

var attacker: CharacterInstance
var defender: CharacterInstance
var skill: Skill
var type: DamageTypes.Type
var modifier: float = 0
var effects: Array[Effect] = []
var options: Dictionary = {}
var actively_cast: bool = false
