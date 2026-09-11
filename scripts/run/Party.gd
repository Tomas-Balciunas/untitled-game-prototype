extends RefCounted

class_name Party

var members: Array[Character] = []

var formation: Array = [null, null, null, null]


func add_member(res: CharacterResource) -> Character:
	if has_member(res.id):
		push_error("Character %s is already in the party" % res.id)
		return

	var inst := Character.new(res)
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
	for m: Character in members:
		if m.resource.id == id:
			return true

	return false

func has_member_by_object(c: Character) -> bool:
	for m: Character in members:
		if m == c:
			return true

	return false

func is_party_full() -> bool:
	return len(members) >= 4


func add_member_to_formation(character: Character) -> int:
	for i in range(formation.size()):
		if not formation[i]:
			formation[i] = character
			return i
	return -1

func get_column_allies(current: Character) -> Array[Character]:
	return [current]

func get_row_allies(_current: Character) -> Array[Character]:
	return get_mass_allies()

func get_blast_allies(current: Character) -> Array[Character]:
	for i in range(formation.size()):
		if formation[i] == current:
			var blast: Array[Character] = [current]
			if i > 0 and formation[i - 1] != null:
				blast.append(formation[i - 1])
			if i < formation.size() - 1 and formation[i + 1] != null:
				blast.append(formation[i + 1])
			return blast

	push_error("Blast Targeting: Target not found!")
	return [current]

func get_adjacent_allies(current: Character) -> Array[Character]:
	return get_blast_allies(current)

func get_mass_allies() -> Array[Character]:
	var mass: Array[Character] = []
	for slot: FormationSlot in formation:
		if slot != null:
			mass.append(slot)
	return mass

func get_average_party_level() -> int:
	var lvl: int = 0

	for member: Character in members:
		lvl += member.level

	return roundi(lvl / len(members))

func game_save() -> Dictionary:
	var members_data := []
	for member in members:
		members_data.append(member.game_save())
	return {"party": members_data}

func game_load(data: Dictionary) -> void:
	members.clear()
	formation = [null, null, null, null]

	if not data.has("party"): return

	var party_data: Array = data["party"]

	for char_data: Dictionary in party_data:
		var inst := Character.create_from_save(char_data)
		if inst:
			members.append(inst)
			var slot_i := add_member_to_formation(inst)
			if slot_i >= 0:
				print("Character added to party: %s" % inst.resource.name)
			else:
				push_error("Adding character to formation error: no free slots")

	for i: int in range(members.size()):
		if i < party_data.size():
			members[i].game_load_effects(party_data[i])
