extends Resource
class_name SkillAction

var attacker: CharacterInstance
var defender: CharacterInstance
var skill: Skill
var type: DamageTypes.Type
var base_value: int = 0

var effects: Array[Effect] = []
