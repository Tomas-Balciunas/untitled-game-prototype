extends Node

var members: Array[CharacterInstance] = []

var formation: Array = [null, null, null, null]


func add_member(res: CharacterResource) -> CharacterInstance:
	if has_member(res.id):
		push_error("Character %s is already in the party" % res.id)
		return

	var inst := CharacterInstance.new(res)
	var slot_i := add_member_to_formation(inst)

	if slot_i >= 0:
		members.append(inst)
		PartyBus.party_member_added.emit(inst, slot_i)
		print("Character added to party: %s" % inst.resource.name)
		return inst
	else:
		push_error("Adding character error: no free slots")
		return null

func has_member(id: String) -> bool:
	for m: CharacterInstance in members:
		if m.resource.id == id:
			return true

	return false


func is_party_full() -> bool:
	return len(members) >= 4


func add_member_to_formation(character: CharacterInstance) -> int:
	for i in range(formation.size()):
		if not formation[i]:
			formation[i] = character
			return i
	return -1

func get_column_allies(current: CharacterInstance) -> Array[CharacterInstance]:
	return [current]

func get_row_allies(_current: CharacterInstance) -> Array[CharacterInstance]:
	return get_mass_allies()

func get_blast_allies(current: CharacterInstance) -> Array[CharacterInstance]:
	for i in range(formation.size()):
		if formation[i] == current:
			var blast: Array[CharacterInstance] = [current]
			if i > 0 and formation[i - 1] != null:
				blast.append(formation[i - 1])
			if i < formation.size() - 1 and formation[i + 1] != null:
				blast.append(formation[i + 1])
			return blast

	push_error("Blast Targeting: Target not found!")
	return [current]

func get_adjacent_allies(current: CharacterInstance) -> Array[CharacterInstance]:
	return get_blast_allies(current)

func get_mass_allies() -> Array[CharacterInstance]:
	var mass: Array[CharacterInstance] = []
	for slot in formation:
		if slot != null:
			mass.append(slot)
	return mass

func to_dict() -> Dictionary:
	var members_data := []
	for member in members:
		members_data.append(member.to_dict())
	return {"party": members_data}

func from_dict(data: Dictionary) -> void:
	members.clear()
	formation = [null, null, null, null]

	if not data.has("party"): return

	for char_data: Dictionary in data["party"]:
		var inst := CharacterInstance.from_dict(char_data)
		if inst:
			members.append(inst)
			var slot_i := add_member_to_formation(inst)
			if slot_i >= 0:
				print("Character added to party: %s" % inst.resource.name)
			else:
				push_error("Adding character to formation error: no free slots")
