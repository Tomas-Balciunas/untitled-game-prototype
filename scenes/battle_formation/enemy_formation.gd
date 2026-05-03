extends FormationBase
class_name EnemyFormation

const ROW_Z          := -2.0
const SLOT_SPACING_X := 2
const MAX_SLOTS      := 5
const FORMATION_SLOT = preload("uid://b1jxfg32brb8x")


func _ready() -> void:
	row_z = ROW_Z
	slot_spacing_x = SLOT_SPACING_X
	max_slots = MAX_SLOTS
	slots.resize(MAX_SLOTS)
	positions = get_centered_positions(MAX_SLOTS, ROW_Z)
	BattleBus.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(dead: CharacterInstance) -> void:
	remove_slot_for(dead)

func get_enemy_instances(resources: Array[CharacterResource]) -> Array[CharacterInstance]:
	var enemies: Array[CharacterInstance] = []
	for r in resources:
		var e := CharacterInstance.new(r)
		enemies.append(e)
	return enemies

func place_all_enemies(enemies: Array[CharacterInstance]) -> void:
	clear_slots()

	var to_place := []
	for e in enemies:
		if to_place.size() < MAX_SLOTS:
			to_place.append(e)
		else:
			push_error("Too many enemies!")

	var start := int((MAX_SLOTS - to_place.size()) * 0.5)
	for i in range(to_place.size()):
		var slot := FORMATION_SLOT.instantiate() as FormationSlot
		var idx := start + i
		slot.position = positions[idx]
		add_child(slot)
		slot.bind(to_place[i])
		slot.capture_home()
		slots[idx] = slot
