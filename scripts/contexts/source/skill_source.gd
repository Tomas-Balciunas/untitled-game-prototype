extends ContextSource
class_name SkillSource


func _init(c: Character, s: Skill) -> void:
	assert(c)
	assert(s)
	character = c
	skill = s
	
func get_type() -> SourceType:
	return ContextSource.SourceType.SKILL

func get_source_name() -> String:
	return skill.name


func game_save() -> Dictionary:
	var data := super.game_save()
	data["character_id"] = character.resource.id if character and character.resource else ""
	data["skill_id"] = skill.id if skill else ""
	return data


static func from_save(data: Dictionary) -> SkillSource:
	var char_inst := ContextSource._find_character_by_id(data.get("character_id", ""))
	var skill_inst := SkillRegistry.get_skill(data.get("skill_id", ""))
	if char_inst == null or skill_inst == null:
		return null
	return SkillSource.new(char_inst, skill_inst)
