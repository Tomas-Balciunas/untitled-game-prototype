extends Resource

class_name ExperienceManager

func can_level_up(character: Character) -> bool:
	return character.current_experience >= exp_needed_to_next_level(character)
	
func exp_needed_to_next_level(character: Character) -> int:
	return 1000 * character.level

func level_up_character(character: Character) -> void:
	while can_level_up(character):
		character.level += 1
		character.unspent_attribute_points += 2
		
		BattleTextLines.print_line("%s has leveled up to %s!" % [character.resource.name, character.level])

		var all_skills: Array[Skill] = []
		all_skills.append_array(character.resource.job.get_skills_for_level(character.level))
		all_skills.append_array(character.resource.get_skills_for_level(character.level))

		for skill: Skill in all_skills:
			character.learnt_skills.append(skill)
			BattleTextLines.print_line("%s has learnt %s!" % [character.resource.name, skill._get_name()])

		var all_effects: Array[Effect] = []
		all_effects.append_array(character.resource.job.get_effects_for_level(character.level))
		all_effects.append_array(character.resource.get_effects_for_level(character.level))

		for effect: Effect in all_effects:
			character.apply_effect(effect, CharacterSource.new(character))
			BattleTextLines.print_line("%s has gained %s!" % [character.resource.name, effect._get_name()])

	StatCalculator.recalculate_all_stats(character)

func grant_experience_to_character(character: Character, amount: int) -> void:
	character.current_experience += amount
