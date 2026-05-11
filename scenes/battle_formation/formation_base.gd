extends Node3D
class_name FormationBase

var row_z: float
var slot_spacing_x: int
var max_slots: int

var slots: Array[FormationSlot] = []
var positions := []

func remove_slot_for(character: Character) -> void:
	for i in range(max_slots):
		var slot: FormationSlot = slots[i]
		if slot and slot.character_instance == character:
			slot.queue_free()
			slots[i] = null
			return

func get_slot_for(who: Character) -> FormationSlot:
	for i in range(max_slots):
		var slot: FormationSlot = slots[i]
		if slot and slot.character_instance == who:
			return slot
	return null

func clear_slots() -> void:
	for slot in slots:
		if slot:
			slot.queue_free()
	slots.fill(null)

func get_centered_positions(count: int, z: float) -> Array:
	var pos := []
	if count <= 0:
		return pos
	var total_width := (count - 1) * slot_spacing_x
	for i in range(count):
		var x := -total_width * 0.5 + i * slot_spacing_x
		pos.append(Vector3(x, 0, z))
	return pos

func get_column(target: Character) -> Array[Character]:
	return [target]

func get_blast(target: Character) -> Array[Character]:
	for i in range(max_slots):
		if slots[i] and slots[i].character_instance == target:
			return get_adjacent_in_row(slots, i)
	push_error("Blast Targeting: Target not found!")
	return [target]

func get_row(_target: Character) -> Array[Character]:
	return get_mass()

func get_adjacent(target: Character) -> Array[Character]:
	var blast: Array[Character] = get_blast(target)
	blast.erase(target)
	return blast

func get_mass() -> Array[Character]:
	var filled: Array[FormationSlot] = slots.filter(func(slot: FormationSlot) -> bool: return slot != null)
	return slots_to_character_instances(filled)

func get_adjacent_in_row(row: Array[FormationSlot], index: int) -> Array[Character]:
	var adjacent: Array[FormationSlot] = []
	adjacent.append(row[index])

	if index > 0 and row[index - 1] != null:
		adjacent.append(row[index - 1])

	if index < max_slots - 1 and row[index + 1] != null:
		adjacent.append(row[index + 1])

	return slots_to_character_instances(adjacent)

func slots_to_character_instances(s: Array[FormationSlot]) -> Array[Character]:
	var result: Array[Character] = []
	for slot in s:
		if slot:
			result.append(slot.character_instance)
	return result

func get_all_slots() -> Array[FormationSlot]:
	var result: Array[FormationSlot] = []
	for slot: FormationSlot in slots:
		if slot != null:
			result.append(slot)
	return result
