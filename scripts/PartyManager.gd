extends Node

var members: Array[CharacterInstance] = []

var formation := [
	[null, null, null],
	[null, null, null]
]


func add_member(res: CharacterResource) -> CharacterInstance:
	if has_member(res.id):
		push_error("Character %s is already in the party" % res.id)
		return
	
	var inst := CharacterInstance.new(res)
	var position := add_member_to_formation(inst)
	
	if position.size() > 0:
		members.append(inst)
		var row_i: int = position[0]
		var slot_i: int = position[1]
		PartyBus.party_member_added.emit(inst, row_i, slot_i)
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
	return len(members) >= 6


func add_member_to_formation(character: CharacterInstance) -> Array:
	for row_i in range(formation.size()):
		for slot_i in range(formation[row_i].size()):
			if not formation[row_i][slot_i]:
				formation[row_i][slot_i] = character
				return [row_i, slot_i]
				
	return []
	
func get_column_allies(current: CharacterInstance) -> Array[CharacterInstance]:
	for row_i in range(formation.size()):
		for slot_i in range(formation[row_i].size()):
			if formation[row_i][slot_i] == current:
				var allies: Array[CharacterInstance] = []
				allies.append(current)
				var other_row_i := 1 - row_i
				var other: CharacterInstance = formation[other_row_i][slot_i]
				
				if other != null:
					allies.append(other)
					
				return allies
				
	push_error("Column Targeting: Target not found!")
	return [current]

func get_row_allies(current: CharacterInstance) -> Array[CharacterInstance]:
	# should always return a row unless something goes horribly wrong
	for row_i in range(formation.size()):
		for slot_i in range(formation[row_i].size()):
			if not formation[row_i][slot_i]:
				continue
			if formation[row_i][slot_i] == current:
				var row: Array[CharacterInstance] = []
				for slot: CharacterInstance in formation[row_i]:
					if slot != null:
						row.append(slot)
						
				return row
				
	push_error("get_row_allies: current not found in formation")
	return [current]
	
func get_blast_allies(current: CharacterInstance) -> Array[CharacterInstance]:
	var blast: Array[CharacterInstance]
	for row_i in range(formation.size()):
		for slot_i in range(formation[row_i].size()):
			if not formation[row_i][slot_i]:
				continue
			if formation[row_i][slot_i] == current:
				var row: Array = formation[row_i]
				blast.append(current)
				if slot_i > 0 and row[slot_i - 1] != null:
					blast.append(row[slot_i - 1])
					
				if slot_i < row.size() - 1 and row[slot_i + 1] != null:
					blast.append(row[slot_i + 1])
				
	return blast
	
func get_adjacent_allies(current: CharacterInstance) -> Array[CharacterInstance]:
	for row_i in range(formation.size()):
		for slot_i in range(formation[row_i].size()):
			if formation[row_i][slot_i] == current:
				var allies: Array[CharacterInstance] = []
				allies.append(current)
				
				if slot_i > 0 and formation[row_i][slot_i - 1] != null:
					allies.append(formation[row_i][slot_i - 1])
				if slot_i < formation[row_i].size() - 1 and formation[row_i][slot_i + 1] != null:
					allies.append(formation[row_i][slot_i + 1])
					
				var other_row_i := 1 - row_i
				var column_ally: CharacterInstance = formation[other_row_i][slot_i]
				
				if column_ally != null and not allies.has(column_ally):
					allies.append(column_ally)
				return allies
				
	push_error("Adjacent Targeting: Target not found!")
	return [current]
				
func get_mass_allies() -> Array[CharacterInstance]:
	var mass: Array[CharacterInstance] = []
	
	for row_i in range(formation.size()):
		for slot_i in range(formation[row_i].size()):
			if not formation[row_i][slot_i]:
				continue
				
			mass.append(formation[row_i][slot_i])
				
	return mass

#func remove_member(character: CharacterInstance):
	#members.erase(character)
	#emit_signal("member_removed", character)

func to_dict() -> Dictionary:
	var members_data := []
	for member in members:
		members_data.append(member.to_dict())
	return {"party": members_data}

func from_dict(data: Dictionary) -> void:
	members.clear()
	formation = [[null, null, null], [null, null, null]]

	if not data.has("party"): return

	for char_data: Dictionary in data["party"]:
		var inst := CharacterInstance.from_dict(char_data)
		if inst:
			members.append(inst)
			var position := add_member_to_formation(inst)
			if position.size() > 0:
				print("Character added to party: %s" % inst.resource.name)
			else:
				push_error("Adding character to formation error: no free slots")
