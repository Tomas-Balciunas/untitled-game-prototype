extends FormationBase
class_name EnemyFormation

const FRONT_ROW_Z    := -2.0
#const BACK_ROW_Z     := 0.0
const SLOT_SPACING_X := 2
const MAX_SLOTS      := 5

const SlotScene = preload("res://scenes/FormationSlot.tscn")

func _ready() -> void:
	front_row_z = FRONT_ROW_Z
	#back_row_z = BACK_ROW_Z
	slot_spacing_x = SLOT_SPACING_X
	max_slots = MAX_SLOTS
	front_slots.resize(MAX_SLOTS)
	back_slots.resize(MAX_SLOTS)
	front_positions = get_centered_positions(MAX_SLOTS, FRONT_ROW_Z)
	#back_positions  = get_centered_positions(MAX_SLOTS, BACK_ROW_Z)
	
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

	var front_enemies := []
	var back_enemies  := []
	for e in enemies:
		#if e.resource.prefers_front_row and front_enemies.size() < MAX_SLOTS:
			#front_enemies.append(e)
		#elif back_enemies.size() < MAX_SLOTS:
			#back_enemies.append(e)
		if front_enemies.size() < MAX_SLOTS:
			front_enemies.append(e)
		else:
			push_error("Too many enemies!")

	var front_start := int((MAX_SLOTS - front_enemies.size()) * 0.5)
	for i in range(front_enemies.size()):
		var slot := SlotScene.instantiate() as FormationSlot
		var idx := front_start + i
		slot.position = front_positions[idx]
		add_child(slot)
		slot.bind(front_enemies[i])
		slot.capture_home()  
		front_slots[idx] = slot
		

	#var back_start := int((MAX_SLOTS - back_enemies.size()) * 0.5)
	#for j in range(back_enemies.size()):
		#var slot := SlotScene.instantiate() as FormationSlot
		#var idx := back_start + j
		#slot.position = back_positions[idx]
		#add_child(slot)
		#slot.bind(back_enemies[j])
		#slot.capture_home() 
		#back_slots[idx] = slot
		#
	#for i in back_enemies.size():
		#_promote_from_back_to_front(i)

func remove_slot_for(enemy: CharacterInstance) -> void:
	for i in range(MAX_SLOTS):
		var slot: FormationSlot = front_slots[i]
		if slot and slot.character_instance == enemy:
			slot.queue_free()
			front_slots[i] = null
			_promote_from_back_to_front(i)
			return

	#for j in range(MAX_SLOTS):
		#var slot := back_slots[j]
		#if slot and slot.character_instance == enemy:
			#slot.queue_free()
			#back_slots[j] = null
			#return
			
