extends Node3D
class_name FormationBase

var front_row_z: float
var back_row_z: float
var slot_spacing_x: int
var max_slots: int



var front_slots: Array[FormationSlot] = []
var back_slots: Array[FormationSlot] = []

var front_positions := []
var back_positions  := []

func remove_slot_for(enemy: CharacterInstance) -> void:
	for i in range(max_slots):
		var slot: FormationSlot = front_slots[i]
		if slot and slot.character_instance == enemy:
			slot.queue_free()
			front_slots[i] = null
			_promote_from_back_to_front(i)
			return

	for j in range(max_slots):
		var slot: FormationSlot = back_slots[j]
		if slot and slot.character_instance == enemy:
			slot.queue_free()
			back_slots[j] = null
			return
			
func get_slot_for(enemy: CharacterInstance) -> FormationSlot:
	for i in range(max_slots):
		var slot: FormationSlot = front_slots[i]
		if slot and slot.character_instance == enemy:
			return slot

	for j in range(max_slots):
		var slot: FormationSlot = back_slots[j]
		if slot and slot.character_instance == enemy:
			return slot
			
	return null

func _promote_from_back_to_front(index: int) -> void:
	var back: FormationSlot = back_slots[index]
	if back and front_slots[index] == null:
		back_slots[index]  = null
		front_slots[index] = back
		back.position      = front_positions[index]
		back.capture_home()

func clear_slots() -> void:
	for slot in front_slots + back_slots:
		if slot:
			slot.queue_free()
	front_slots.fill(null)
	back_slots.fill(null)

func get_centered_positions(count: int, z: float) -> Array:
	var positions := []
	if count <= 0:
		return positions
	var total_width := (count - 1) * slot_spacing_x
	for i in range(count):
		var x := -total_width * 0.5 + i * slot_spacing_x
		positions.append(Vector3(x, 0, z))
		
	return positions
	
func get_column_enemies(target: CharacterInstance) -> Array[CharacterInstance]:
	for i in range(max_slots):
		if front_slots[i] and front_slots[i].character_instance == target:
			return get_adjacent_in_column(back_slots, i, front_slots[i])
		if back_slots[i] and back_slots[i].character_instance == target:
			return get_adjacent_in_column(front_slots, i, back_slots[i])
	
	push_error("Column Targeting: Target not found!")
	return [target]
	
func get_blast_enemies(target: CharacterInstance) -> Array[CharacterInstance]:
	for i in range(max_slots):
		if front_slots[i] and front_slots[i].character_instance == target:
			return get_adjacent_in_row(front_slots, i)
		if back_slots[i] and back_slots[i].character_instance == target:
			return get_adjacent_in_row(back_slots, i)
	
	push_error("Blast Targeting: Target not found!")
	return [target]

func get_row_enemies(target: CharacterInstance) -> Array[FormationSlot]:
	for i in range(max_slots):
		var slot: FormationSlot = front_slots[i]
		if slot and slot.character_instance == target:
			return front_slots
	return back_slots
	
func get_adjacent_enemies(target: CharacterInstance) -> Array[CharacterInstance]:
	for i in range(max_slots):
		if front_slots[i] and front_slots[i].character_instance == target:
			var row :=  get_adjacent_in_row(front_slots, i)
			var column := get_adjacent_in_column(back_slots, i, front_slots[i])
			return array_unique(row, column)
			
		if back_slots[i] and back_slots[i].character_instance == target:
			var row :=  get_adjacent_in_row(back_slots, i)
			var column := get_adjacent_in_column(front_slots, i, back_slots[i])
			return array_unique(row, column)
			
	push_error("Adjacent Targeting: Target not found!")
	return [target]
	
func get_mass_enemies() -> Array[CharacterInstance]:
	var mass: Array[FormationSlot] = (front_slots + back_slots).filter(func(slot): return slot != null)
		
	return slots_to_character_instances(mass)
	
func get_adjacent_in_row(row: Array[FormationSlot], index: int) -> Array[CharacterInstance]:
	var adjacent: Array[FormationSlot] = []
	adjacent.append(row[index])
	
	if index > 0 and row[index - 1] != null:
		adjacent.append(row[index - 1])
		
	if index < max_slots - 1 and row[index + 1] != null:
		adjacent.append(row[index + 1])

	return slots_to_character_instances(adjacent)

func get_adjacent_in_column(row: Array[FormationSlot], index: int, target: FormationSlot) -> Array[CharacterInstance]:
	var adjacent: Array[FormationSlot] = []
	adjacent.append(target)
	
	if row[index] != null:
		adjacent.append(row[index])

	return slots_to_character_instances(adjacent)
	
func array_unique(arr1: Array[CharacterInstance], arr2: Array[CharacterInstance]) -> Array[CharacterInstance]:
	var unique := arr1
	
	for item in arr2:
		if arr1.has(item):
			continue
		arr1.append(item)
	
	return unique

func slots_to_character_instances(slots: Array[FormationSlot]) -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for slot in slots:
		result.append(slot.character_instance)

	return result
