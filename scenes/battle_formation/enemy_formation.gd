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

func _on_enemy_died(dead: Character) -> void:
	remove_slot_for(dead)

func get_enemy_instances(encounter_enemies: Array[EncounterEnemy]) -> Array[Character]:
	var enemies: Array[Character] = []
	
	for encounter_enemy in encounter_enemies:
		if len(enemies) >= MAX_SLOTS:
			return enemies
		
		if encounter_enemy.resource == null:
			push_error("Encounter enemy is missing a resource!")
			continue
		
		var enemy: Character = Character.new(encounter_enemy.resource, encounter_enemy.level)
		
		if encounter_enemy.name_override != "":
			enemy.name = encounter_enemy.name_override
		
		for extra_modifier: StatModifier in encounter_enemy.stat_modifiers:
			enemy.state.add_modifier(extra_modifier)
		
		for extra_effect: Effect in encounter_enemy.extra_effects:
			enemy.apply_effect(extra_effect, CharacterSource.new(enemy))
		
		StatCalculator.recalculate_all_stats(enemy)
		enemy.full_heal()
		enemies.append(enemy)
	return enemies

func place_all_enemies(enemies: Array[Character]) -> void:
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
