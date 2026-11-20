@abstract
extends Resource
class_name ContextSource

enum SourceType { CHARACTER, ITEM, SKILL, TRAP, MOVEMENT, EFFECT, UNKNOWN, HAZARD }

var character: Character = null
var skill: Skill = null
var item: Item = null
var trap: Trap = null
var effect: Effect = null


@abstract
func get_type() -> SourceType

@abstract
func get_source_name() -> String

func get_actor() -> Character:
	return character

func get_damage_type() -> DamageTypes.Type:
	return DamageTypes.Type.PHYSICAL


func game_save() -> Dictionary:
	return { "type": get_type() }


static func create_from_save(data: Dictionary) -> ContextSource:
	var t: int = data.get("type", SourceType.UNKNOWN)
	match t:
		SourceType.CHARACTER:
			return CharacterSource.from_save(data)
		SourceType.SKILL:
			return SkillSource.from_save(data)
		SourceType.ITEM:
			return ItemSource.from_save(data)
		SourceType.TRAP:
			return TrapSource.from_save(data)
		SourceType.MOVEMENT:
			return MovementSource.new()
		SourceType.HAZARD:
			return HazardSource.from_save(data)
	SaveManager.report_load_issue("ContextSource.create_from_save: unknown source type %s" % t)
	return null


# Resolve a character by its resource id (party-only — enemies are transient).
static func _find_character_by_id(char_id: String) -> Character:
	if char_id.is_empty():
		return null
	for m: Character in RunState.current.party.members:
		if m.resource and m.resource.id == char_id:
			return m
	return null
