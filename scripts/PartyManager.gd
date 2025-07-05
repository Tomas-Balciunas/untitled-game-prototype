extends Node

signal member_added(character, row_i, slot_i)
#signal member_removed(character)

var members: Array[CharacterInstance] = []

var formation = [
	[null, null, null],
	[null, null, null]
]

func _ready() -> void:
	for id in [1, 2]:
		add_member(id)

func add_member(id: int) -> void:
	var res := CharacterRegistry.get_character(id)
	if res:
		var inst := CharacterInstance.new(res)
		members.append(inst)
		var position = add_member_to_formation(inst)
		
		if position.size() > 0:
			var row_i = position[0]
			var slot_i = position[1]
			emit_signal("member_added", inst, row_i, slot_i)
			print("Character added to party: %s" % inst.resource.name)
		else:
			push_error("Adding character to formation error: no free slots")
		
	else:
		push_error("Character not found: %s" % id)

func add_member_to_formation(character: CharacterInstance) -> Array:
	for row_i in range(formation.size()):
		for slot_i in range(formation[row_i].size()):
			if not formation[row_i][slot_i]:
				formation[row_i][slot_i] = character
				return [row_i, slot_i]
	return []

#func remove_member(character: CharacterInstance):
	#members.erase(character)
	#emit_signal("member_removed", character)
