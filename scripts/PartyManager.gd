extends Node

signal member_added(character)
signal member_removed(character)

var main_character: CharacterResource = preload("res://characters/Skelly.tres")
var main_character2: CharacterResource = preload("res://characters/Lili.tres")

var members: Array[CharacterInstance] = [
	CharacterInstance.new(main_character),
	CharacterInstance.new(main_character2),
	CharacterInstance.new(main_character),
	CharacterInstance.new(main_character2)
]

func add_member(id: int) -> void:
	var res := CharacterRegistry.get_character(id)
	if res:
		var inst := CharacterInstance.new(res)
		members.append(inst)
		emit_signal("member_added", inst)
	else:
		push_error("Character not found: %s" % id)

#func remove_member(character: CharacterInstance):
	#members.erase(character)
	#emit_signal("member_removed", character)
