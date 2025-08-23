extends StatModifier
class_name IQToAttackModifier

var conversion: float = 0.5

func compute_value(character: CharacterInstance):
	return round(character.attributes.iq * conversion)

func get_description() -> String:
	return "Converts %s%% of IQ into attack power" % int(round(100 * 0.5))
