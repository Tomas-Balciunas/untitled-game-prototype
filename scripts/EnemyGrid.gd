extends Node3D
class_name EnemyFormation

const FRONT_ROW_Z    := -2.0
const BACK_ROW_Z     := 0.0
const SLOT_SPACING_X := 2
const MAX_SLOTS      := 5

const Enemy3DScene = preload("res://scenes/EnemySlot.tscn")

var front_slots: Array[EnemySlot] = []
var back_slots: Array[EnemySlot] = []

var front_positions := []
var back_positions  := []

func _ready() -> void:
	front_slots.resize(MAX_SLOTS)
	back_slots.resize(MAX_SLOTS)
	front_positions = get_centered_positions(MAX_SLOTS, FRONT_ROW_Z)
	back_positions  = get_centered_positions(MAX_SLOTS, BACK_ROW_Z)
	
func _on_enemy_died(dead: CharacterInstance):
	remove_slot_for(dead)
	
func get_enemy_instances(resources: Array[CharacterResource]) -> Array[CharacterInstance]:
	var enemies: Array[CharacterInstance] = []
	for r in resources:
		var e = CharacterInstance.new(r)
		enemies.append(e)
	
	return enemies

func place_all_enemies(enemies: Array[CharacterInstance]) -> void:
	clear_slots()

	var front_enemies := []
	var back_enemies  := []
	for e in enemies:
		if e.resource.prefers_front_row and front_enemies.size() < MAX_SLOTS:
			front_enemies.append(e)
		elif back_enemies.size() < MAX_SLOTS:
			back_enemies.append(e)
		elif front_enemies.size() < MAX_SLOTS:
			front_enemies.append(e)
		else:
			push_error("Too many enemies!")

	var front_start = int((MAX_SLOTS - front_enemies.size()) * 0.5)
	for i in range(front_enemies.size()):
		var slot = Enemy3DScene.instantiate() as EnemySlot
		var idx = front_start + i
		slot.position = front_positions[idx]
		add_child(slot)
		slot.bind(front_enemies[i])
		slot.capture_home()  
		front_slots[idx] = slot
		

	var back_start = int((MAX_SLOTS - back_enemies.size()) * 0.5)
	for j in range(back_enemies.size()):
		var slot = Enemy3DScene.instantiate() as EnemySlot
		var idx = back_start + j
		slot.position = back_positions[idx]
		add_child(slot)
		slot.bind(back_enemies[j])
		slot.capture_home() 
		back_slots[idx] = slot
		
	for i in back_enemies.size():
		_promote_from_back_to_front(i)

func remove_slot_for(enemy: CharacterInstance) -> void:
	for i in range(MAX_SLOTS):
		var slot = front_slots[i]
		if slot and slot.character_instance == enemy:
			slot.queue_free()
			front_slots[i] = null
			_promote_from_back_to_front(i)
			return

	for j in range(MAX_SLOTS):
		var slot = back_slots[j]
		if slot and slot.character_instance == enemy:
			slot.queue_free()
			back_slots[j] = null
			return
			
func get_slot_for(enemy: CharacterInstance):
	for i in range(MAX_SLOTS):
		var slot = front_slots[i]
		if slot and slot.character_instance == enemy:
			return slot

	for j in range(MAX_SLOTS):
		var slot = back_slots[j]
		if slot and slot.character_instance == enemy:
			return slot

func _promote_from_back_to_front(index: int) -> void:
	var back = back_slots[index]
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
	var total_width = (count - 1) * SLOT_SPACING_X
	for i in range(count):
		var x = -total_width * 0.5 + i * SLOT_SPACING_X
		positions.append(Vector3(x, 0, z))
		
	return positions

func _on_mouse_entered() -> void:
	print(self.get_children())
	
func get_column_enemies(target: CharacterInstance) -> Array[CharacterInstance]:
	for i in range(MAX_SLOTS):
		if front_slots[i] and front_slots[i].character_instance == target:
			return get_adjacent_in_column(back_slots, i, front_slots[i])
		if back_slots[i] and back_slots[i].character_instance == target:
			return get_adjacent_in_column(front_slots, i, back_slots[i])
	
	push_error("Column Targeting: Target not found!")
	return [target]
	
func get_blast_enemies(target: CharacterInstance) -> Array[CharacterInstance]:
	for i in range(MAX_SLOTS):
		if front_slots[i] and front_slots[i].character_instance == target:
			return get_adjacent_in_row(front_slots, i)
		if back_slots[i] and back_slots[i].character_instance == target:
			return get_adjacent_in_row(back_slots, i)
	
	push_error("Blast Targeting: Target not found!")
	return [target]

func get_row_enemies(target: CharacterInstance):
	for i in range(MAX_SLOTS):
		var slot = front_slots[i]
		if slot and slot.character_instance == target:
			return front_slots
	return back_slots
	
func get_adjacent_enemies(target: CharacterInstance) -> Array[CharacterInstance]:
	for i in range(MAX_SLOTS):
		if front_slots[i] and front_slots[i].character_instance == target:
			var row =  get_adjacent_in_row(front_slots, i)
			var column = get_adjacent_in_column(back_slots, i, front_slots[i])
			return array_unique(row, column)
			
		if back_slots[i] and back_slots[i].character_instance == target:
			var row =  get_adjacent_in_row(back_slots, i)
			var column = get_adjacent_in_column(front_slots, i, back_slots[i])
			return array_unique(row, column)
			
	push_error("Adjacent Targeting: Target not found!")
	return [target]
	
func get_mass_enemies() -> Array[CharacterInstance]:
	var mass: Array[EnemySlot] = (front_slots + back_slots).filter(func(slot): return slot != null)
		
	return slots_to_character_instances(mass)
	
func get_adjacent_in_row(row: Array[EnemySlot], index: int) -> Array[CharacterInstance]:
	var adjacent: Array[EnemySlot] = []
	adjacent.append(row[index])
	
	if index > 0 and row[index - 1] != null:
		adjacent.append(row[index - 1])
		
	if index < MAX_SLOTS - 1 and row[index + 1] != null:
		adjacent.append(row[index + 1])

	return slots_to_character_instances(adjacent)

func get_adjacent_in_column(row: Array[EnemySlot], index: int, target: EnemySlot) -> Array[CharacterInstance]:
	var adjacent: Array[EnemySlot] = []
	adjacent.append(target)
	
	if row[index] != null:
		adjacent.append(row[index])

	return slots_to_character_instances(adjacent)
	
func array_unique(arr1: Array[CharacterInstance], arr2: Array[CharacterInstance]) -> Array[CharacterInstance]:
	var unique = arr1
	
	for item in arr2:
		if arr1.has(item):
			continue
		arr1.append(item)
	
	return unique

func slots_to_character_instances(slots: Array[EnemySlot]) -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for slot in slots:
		result.append(slot.character_instance)

	return result
