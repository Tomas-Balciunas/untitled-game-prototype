extends Job

class_name MageClass

const ARCANE_BLAST = preload("res://skills/_offensive/arcane_blast.tres")
const SPELL_MASTERY = preload("res://effect/_passive/spell_mastery/spell_mastery.tres")


func get_skills_for_level(lvl: int) -> Array:
	match lvl:
		3: return [ARCANE_BLAST]
	return []


func get_effects_for_level(lvl: int) -> Array:
	match lvl:
		5: return [SPELL_MASTERY]
	return []

func get_equippable_weapons() -> Array[ItemTypes.WeaponType]:
	return []
