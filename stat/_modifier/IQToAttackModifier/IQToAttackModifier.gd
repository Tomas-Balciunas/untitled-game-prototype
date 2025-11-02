extends StatModifier
class_name IQToAttackModifier

func compute_value(character: CharacterInstance) -> float:
	return roundf(character.attributes.iq * value)

func get_description() -> String:
	return "Converts %s%% of IQ into attack power" % int(round(100 * value))
