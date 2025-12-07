extends ContextSource
class_name SkillSource


func _init(c: CharacterInstance, s: Skill) -> void:
	character = c
	skill = s
	
func get_type() -> SourceType:
	return ContextSource.SourceType.SKILL

func get_source_name() -> String:
	return skill.name
