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
