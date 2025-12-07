@abstract
extends Resource
class_name ContextSource

enum SourceType { CHARACTER, ITEM, SKILL, TRAP, UNKNOWN }

var character: CharacterInstance = null
var skill: Skill = null
var item: ItemInstance = null
var trap: Trap = null


@abstract
func get_type() -> SourceType

@abstract
func get_source_name() -> String
