extends Resource

class_name Gear

enum Type {
	WEAPON
}

@export var name: String
@export var type: Type
@export var modifiers: Array[StatModifier]
@export var effects: Array[Effect]

func equip(character: CharacterInstance):
	for e in effects:
		character.effects.append(e)
	
	for m in modifiers:
		character.stats.modifiers.append(m)
	
func unequip():
	pass
