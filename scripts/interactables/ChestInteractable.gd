extends Interactable

class_name ChestInteractable

enum Contents { GEAR_ONLY, CONSUMABLES_ONLY, BOTH }

const CHEST_BASIC = preload("uid://bnoe7tf7523jg")
const CHEST_BASIC_UNLOCKED = preload("uid://bv17wkj3y400d")

@export var id: String
@export var random: bool = false
@export var quantity: int = 2
@export var contents: Contents = Contents.GEAR_ONLY
@export var chest: Chest

@onready var sprite_3d: Sprite3D = $Sprite3D
@export var chest_asset_locked: Texture2D = null
@export var chest_asset_unlocked: Texture2D = null


func on_map_loaded(_map_data: Dictionary) -> void:
	if !ObjectBus.chest_state_changed.is_connected(on_chest_state_changed):
		ObjectBus.chest_state_changed.connect(on_chest_state_changed)

	var data: Dictionary = MapInstance.chest_state.get(id, {})

	if !data.is_empty():
		chest = game_load(data)
		return

	if chest and not chest.custom_items.is_empty():
		_instantiate_custom_items()
	else:
		build_chest(_map_data)

	update_chest_state()
	
	if chest:
		chest.chest_unlocked.connect(on_chest_unlocked)
	
	if chest.key != null:
		set_asset_locked()
	else:
		set_asset_unlocked()

func _instantiate_custom_items() -> void:
	chest.set_locked(null)
		
	for resource: ItemResource in chest.custom_items:
		chest.items.append(resource._build_instance())
	chest.custom_items.clear()

func _interact() -> void:
	if !chest:
		push_error("Chest was not built!")
		return

	ObjectBus.open_chest_requested.emit(chest)

func build_items(_map_data: Dictionary) -> Array[Item]:
	var items: Array[Item] = []

	match contents:
		Contents.GEAR_ONLY:
			for g: Gear in GearGenerator.new(quantity).generate():
				items.append(g)
		Contents.CONSUMABLES_ONLY:
			for c: Consumable in ConsumableGenerator.new(quantity).generate():
				items.append(c)
		Contents.BOTH:
			var gear_qty := 0
			for i in range(quantity):
				if randi() % 2 == 0:
					gear_qty += 1
			var cons_qty := quantity - gear_qty

			if gear_qty > 0:
				for g: Gear in GearGenerator.new(gear_qty).generate():
					items.append(g)
			if cons_qty > 0:
				for c: Consumable in ConsumableGenerator.new(cons_qty).generate():
					items.append(c)

	return items

func build_chest(map_data: Dictionary) -> void:
	var trapped = randf() > 0.5
	
	var inst := Chest.new()
	inst.id = id
	inst.items = build_items(map_data)
	
	if trapped:
		inst.trap = TrapRegistry.get_random_trap()

	chest = inst
	
func update_chest_state() -> void:
	MapInstance.chest_state[id] = game_save()
	
func on_chest_state_changed(_chest: Chest) -> void:
	if chest and chest.id == _chest.id:
		update_chest_state()

func on_chest_unlocked() -> void:
	set_asset_unlocked()

func set_asset_locked() -> void:
	if chest_asset_locked:
		sprite_3d.texture = chest_asset_locked
	else:
		sprite_3d.texture = CHEST_BASIC

func set_asset_unlocked() -> void:
	if chest_asset_unlocked:
		sprite_3d.texture = chest_asset_unlocked
	else:
		sprite_3d.texture = CHEST_BASIC_UNLOCKED

func game_save() -> Dictionary:
	var items := []

	for item: Item in chest.items:
		items.append(item.game_save())

	return {
		"id": id,
		"items": items,
		"was_opened": chest.was_opened,
		"random": random
	}

func game_load(data: Dictionary) -> Chest:
	if !data:
		return null

	var items: Array[Item] = []

	for item_data: Dictionary in data.get("items", []):
		var item := Item.create_from_save(item_data)
		if item:
			items.append(item)

	var updated_chest := Chest.new()
	updated_chest.id = data.get("id")
	updated_chest.was_opened = data.get("was_opened")
	updated_chest.items = items

	return updated_chest
