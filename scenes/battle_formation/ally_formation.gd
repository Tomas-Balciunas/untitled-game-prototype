extends FormationBase

class_name AllyFormation

const PLAYER = preload("uid://ed1wo7vfltsb")
const FORMATION_SLOT = preload("uid://b1jxfg32brb8x")


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
			var slot := FORMATION_SLOT.instantiate() as FormationSlot
			add_child(slot)
			var idx := front_start + i
			slot.position = front_positions[idx]
			slot.bind(front_allies[i])
			slot.capture_home() 
			front_slots[idx] = slot
				

	var back_start := int((MAX_SLOTS - back_allies.size()) * 0.5)
	for j in range(back_allies.size()):
		var inst: CharacterInstance = back_allies[j]
		if inst:
			var slot := FORMATION_SLOT.instantiate() as FormationSlot
			var idx := back_start + j
			slot.position = back_positions[idx]
			add_child(slot)
			slot.bind(back_allies[j])
			slot.capture_home() 
			back_slots[idx] = slot
		
	for i in back_allies.size():
		_promote_from_back_to_front(i)
