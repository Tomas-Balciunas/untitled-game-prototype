extends Resource

class_name ExperienceManager

func can_level_up(character: CharacterInstance) -> bool:
	return character.current_experience >= exp_needed_to_next_level(character)
	
func exp_needed_to_next_level(character: CharacterInstance) -> int:
	return 1000 * character.level

func level_up_character(character: CharacterInstance) -> void:
	while can_level_up(character):
		character.level += 1
		character.unspent_attribute_points += 2
		
		var class_skill: Skill = character.resource.job.get_skill_for_level(character.level)
		var character_skill: Skill = character.resource.get_skill_for_level(character.level)
		
		BattleTextLines.print_line("%s has leveled up to %s!" % [character.resource.name, character.level])
		
		for skill: Skill in [class_skill, character_skill]:
			if skill:
				character.learnt_skills.append(skill)
				BattleTextLines.print_line("%s has learnt %s!" % [character.resource.name, skill._get_name()])
		
		var class_effect: Effect = character.resource.job.get_effect_for_level(character.level)
		var character_effect: Effect = character.resource.get_effect_for_level(character.level)
		
		for effect: Effect in [class_effect, character_effect]:
			if effect:
				character.apply_effect(effect, CharacterSource.new(character))
				BattleTextLines.print_line("%s has learnt %s!" % [character.resource.name, effect._get_name()])

	character.stats.recalculate_stats()

func grant_experience_to_character(character: CharacterInstance, amount: int) -> void:
	character.current_experience += amount
