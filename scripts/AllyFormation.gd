extends FormationBase

class_name AllyFormation

const FRONT_ROW_Z    := -8.0
const BACK_ROW_Z     := -10.0
const SLOT_SPACING_X := 2
const MAX_SLOTS      := 3
const PLAYER = preload("uid://ed1wo7vfltsb")

const SlotScene = preload("res://scenes/FormationSlot.tscn")

func _ready() -> void:
	front_row_z = FRONT_ROW_Z
	back_row_z = BACK_ROW_Z
	slot_spacing_x = SLOT_SPACING_X
	max_slots = MAX_SLOTS
	front_slots.resize(MAX_SLOTS)
	back_slots.resize(MAX_SLOTS)
	front_positions = get_centered_positions(MAX_SLOTS, FRONT_ROW_Z)
	back_positions  = get_centered_positions(MAX_SLOTS, BACK_ROW_Z)
	
	if MAX_SLOTS % 2 != 0:
		var mid_index := int(MAX_SLOTS / 2)
		front_positions[mid_index].z += 0.3
		back_positions[mid_index].z += 0.3

func place_all_allies() -> void:
	clear_slots()

	var front_allies := []
	var back_allies  := []
	
	for a: CharacterInstance in PartyManager.formation[0]:
		if front_allies.size() < MAX_SLOTS:
			front_allies.append(a)
		else:
			push_error("Too many allies in front row!")
			
	for b: CharacterInstance in PartyManager.formation[1]:
		if back_allies.size() < MAX_SLOTS:
			back_allies.append(b)
		else:
			push_error("Too many allies in back row!")

	var front_start := int((MAX_SLOTS - front_allies.size()) * 0.5)
	for i in range(front_allies.size()):
		var inst: CharacterInstance = front_allies[i]
		if inst:
			var slot := SlotScene.instantiate() as FormationSlot
			add_child(slot)
			var idx := front_start + i
			slot.position = front_positions[idx]
			slot.bind(front_allies[i])
			slot.capture_home() 
			front_slots[idx] = slot
			
			if inst.is_main:
				var camera := PLAYER.instantiate()
				slot.add_child(camera)
				camera.transform = Transform3D()
				camera.transform.origin = Vector3(0, 0.2, 0)
				camera.rotation_degrees.y = 180
				

	var back_start := int((MAX_SLOTS - back_allies.size()) * 0.5)
	for j in range(back_allies.size()):
		var inst: CharacterInstance = back_allies[j]
		if inst:
			var slot := SlotScene.instantiate() as FormationSlot
			var idx := back_start + j
			slot.position = back_positions[idx]
			add_child(slot)
			slot.bind(back_allies[j])
			slot.capture_home() 
			back_slots[idx] = slot
		
	for i in back_allies.size():
		_promote_from_back_to_front(i)
