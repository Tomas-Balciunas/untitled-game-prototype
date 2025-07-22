extends Node3D
class_name EnemyFormation

const FRONT_ROW_Z    := -2.0
const BACK_ROW_Z     := 0.0
const SLOT_SPACING_X := 2.5
const MAX_SLOTS      := 5

const Enemy3DScene = preload("res://scenes/EnemySlot.tscn")

var front_slots := []
var back_slots  := []

var front_positions := []
var back_positions  := []

func _ready() -> void:
	front_slots.resize(MAX_SLOTS)
	back_slots.resize(MAX_SLOTS)
	front_positions = get_centered_positions(MAX_SLOTS, FRONT_ROW_Z)
	back_positions  = get_centered_positions(MAX_SLOTS, BACK_ROW_Z)

func place_all_enemies(enemies: Array[CharacterInstance]) -> void:
	clear_slots()

	var front_enemies := []
	var back_enemies  := []
	for e in enemies:
		if e.resource.prefers_front_row and front_enemies.size() < MAX_SLOTS:
			front_enemies.append(e)
		elif back_enemies.size() < MAX_SLOTS:
			back_enemies.append(e)
		else:
			push_warning("Too many enemies!")

	var front_start = int((MAX_SLOTS - front_enemies.size()) * 0.5)
	for i in range(front_enemies.size()):
		var slot = Enemy3DScene.instantiate() as EnemySlot
		var idx = front_start + i
		slot.bind(front_enemies[i])
		slot.position = front_positions[idx]
		add_child(slot)
		front_slots[idx] = slot

	var back_start = int((MAX_SLOTS - back_enemies.size()) * 0.5)
	for j in range(back_enemies.size()):
		var slot = Enemy3DScene.instantiate() as EnemySlot
		var idx = back_start + j
		slot.bind(back_enemies[j])
		slot.position = back_positions[idx]
		add_child(slot)
		back_slots[idx] = slot

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

func _promote_from_back_to_front(index: int) -> void:
	var back = back_slots[index]
	if back:
		back_slots[index]  = null
		front_slots[index] = back
		back.position      = front_positions[index]

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

func get_row_enemies(target: CharacterInstance):
	for i in range(MAX_SLOTS):
		var slot = front_slots[i]
		if slot and slot.character_instance == target:
			return front_slots
	return back_slots
