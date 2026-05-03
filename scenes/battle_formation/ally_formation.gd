extends FormationBase

class_name AllyFormation

const ROW_Z          := -8.0
const SLOT_SPACING_X := 2
const MAX_SLOTS      := 4
const PLAYER = preload("uid://ed1wo7vfltsb")
const FORMATION_SLOT = preload("uid://b1jxfg32brb8x")


func _ready() -> void:
	row_z = ROW_Z
	slot_spacing_x = SLOT_SPACING_X
	max_slots = MAX_SLOTS
	slots.resize(MAX_SLOTS)
	positions = get_centered_positions(MAX_SLOTS, ROW_Z)

func place_all_allies() -> void:
	clear_slots()

	var allies := []
	for a: CharacterInstance in PartyManager.formation:
		if allies.size() < MAX_SLOTS:
			allies.append(a)
		else:
			push_error("Too many allies!")

	var start := int((MAX_SLOTS - allies.size()) * 0.5)
	for i in range(allies.size()):
		var inst: CharacterInstance = allies[i]
		if inst:
			var slot := FORMATION_SLOT.instantiate() as FormationSlot
			add_child(slot)
			var idx := start + i
			slot.position = positions[idx]
			slot.bind(allies[i])
			slot.capture_home()
			slots[idx] = slot
