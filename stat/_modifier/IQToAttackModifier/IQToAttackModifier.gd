extends StatModifier
class_name IQToAttackModifier

func compute_value(character: CharacterInstance):
	var bonus = round(character.attributes.iq * 0.5)
	print("bonus ", bonus)
	return bonus
