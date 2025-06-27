extends Node

var main_character: CharacterResource = preload("res://characters/Skelly.tres")

var party_members: Array[CharacterInstance] = [
	CharacterInstance.new(main_character)
]

func hire(id: int) -> void:
	var res := CharacterRegistry.get_character(id)
	if res:
		var inst = CharacterInstance.new(res)
		party_members.append(inst)
	else:
		push_error("Character not found: %s" % id)
