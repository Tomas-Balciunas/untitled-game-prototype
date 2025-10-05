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
		BattleTextLines.print_line("%s has leveled up to %s!" % [character.resource.name, character.level])
	
	character.stats.recalculate_stats()

func grant_experience_to_character(character: CharacterInstance, amount: int):
	character.current_experience += amount
