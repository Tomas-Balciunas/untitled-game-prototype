extends StatModifier
class_name IQToAttackModifier

func compute_value(character: CharacterInstance):
	return round(character.attributes.iq * 0.5)
