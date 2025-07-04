extends Node

signal member_added(character)
#signal member_removed(character)

var main_character: CharacterResource = preload("res://characters/Skelly.tres")
var main_character2: CharacterResource = preload("res://characters/Lili.tres")

var members: Array[CharacterInstance] = [
	CharacterInstance.new(main_character),
	CharacterInstance.new(main_character2),
	CharacterInstance.new(main_character),
	CharacterInstance.new(main_character2),
]

var formation = [
	[CharacterInstance.new(main_character), null, null],
	[null, CharacterInstance.new(main_character2), null]
]

#func _ready() -> void:
	#for i in members.size():
		#if i < 3:
			#formation[0].append(members[i])
		#else:
			#formation[1].append(members[i])

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
