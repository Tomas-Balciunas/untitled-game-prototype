extends Node3D

const FRONT_ROW_Z = -2
const BACK_ROW_Z = 0
const SLOT_SPACING_X = 2.5
const MAX_SLOTS = 5

const Enemy3DScene = preload("res://scenes/EnemySlot.tscn")

var occupied_slots_front = []
var occupied_slots_back = []

func _ready():
	occupied_slots_front.resize(MAX_SLOTS)
	occupied_slots_back.resize(MAX_SLOTS)

	for i in range(MAX_SLOTS):
		occupied_slots_front[i] = false
		occupied_slots_back[i] = false

func place_all_enemies(enemies: Array):
	var front_enemies = []
	var back_enemies = []

	for enemy in enemies:
		if enemy.resource.prefers_front_row:
			if front_enemies.size() < MAX_SLOTS:
				front_enemies.append(enemy)
			elif back_enemies.size() < MAX_SLOTS:
				back_enemies.append(enemy)
			else:
				push_warning("Too many enemies!")
		else:
			if back_enemies.size() < MAX_SLOTS:
				back_enemies.append(enemy)
			elif front_enemies.size() < MAX_SLOTS:
				front_enemies.append(enemy)
			else:
				push_warning("Too many enemies!")

	var front_positions = get_centered_positions(front_enemies.size(), FRONT_ROW_Z)
	var back_positions = get_centered_positions(back_enemies.size(), BACK_ROW_Z)

	for i in range(front_enemies.size()):
		var enemy_node = Enemy3DScene.instantiate()
		enemy_node.bind(front_enemies[i])
		enemy_node.position = front_positions[i]
		add_child(enemy_node)
		occupied_slots_front[i] = true

	for i in range(back_enemies.size()):
		var enemy_node = Enemy3DScene.instantiate()
		enemy_node.bind(back_enemies[i])
		enemy_node.position = back_positions[i]
		add_child(enemy_node)
		occupied_slots_back[i] = true

func clear_slots():
	for i in range(MAX_SLOTS):
		occupied_slots_front[i] = false
		occupied_slots_back[i] = false

func get_centered_positions(count: int, z: float) -> Array:
	var positions = []
	if count == 0:
		return positions
	var total_width = (count - 1) * SLOT_SPACING_X
	for i in range(count):
		var x = -total_width / 2 + i * SLOT_SPACING_X
		positions.append(Vector3(x, 0, z))
	return positions
