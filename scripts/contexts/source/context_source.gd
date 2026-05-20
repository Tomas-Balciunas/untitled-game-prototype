@abstract
extends Resource
class_name ContextSource

enum SourceType { CHARACTER, ITEM, SKILL, TRAP, MOVEMENT, UNKNOWN }

var character: Character = null
var skill: Skill = null
var item: Item = null
var trap: Trap = null


@abstract
func get_type() -> SourceType

@abstract
func get_source_name() -> String

func get_actor() -> Character:
	return character


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
	push_error("ContextSource.create_from_save: unknown source type %s" % t)
	return null


# Resolve a character by its resource id (party-only — enemies are transient).
static func _find_character_by_id(char_id: String) -> Character:
	if char_id.is_empty():
		return null
	for m: Character in PartyManager.members:
		if m.resource and m.resource.id == char_id:
			return m
	return null
