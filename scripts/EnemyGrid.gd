extends Control

@onready var front_row = $VBoxContainer/FrontRow
@onready var back_row = $VBoxContainer/BackRow

const EnemySlotScene = preload("res://scenes/EnemySlot.tscn")

var slots := []
var occupied_grid := {}

func _ready():
	create_grid()

func create_grid():
	for i in range(5):
		var slot = EnemySlotScene.instantiate()
		front_row.add_child(slot)
		slots.append(slot)

	for i in range(5):
		var slot = EnemySlotScene.instantiate()
		back_row.add_child(slot)
		slots.append(slot)

func place_enemy(character_instance: CharacterInstance, desired_row: String = "front"):
	var target_row = front_row if desired_row == "front" else back_row

	for slot in target_row.get_children():
		if slot.character_instance == null:
			slot.bind(character_instance)
			return

func clear_grid():
	for slot in slots:
		slot.clear()
