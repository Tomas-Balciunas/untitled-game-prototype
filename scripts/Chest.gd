extends Resource
class_name Chest

@export var id: String
@export var was_opened: bool = false
@export var was_trapped: bool = false
@export var was_locked: bool = false
@export var trap: Trap = null
var key: QuestItem = null
@export var original_key: QuestItemResource = null
@export var custom_items: Array[ItemResource] = []
var items: Array[Item] = []

func remove_item(_item: Item) -> bool:
	for item in items:
		if item == _item:
			items.erase(item)
			
			return true
	
	return false

func set_locked(_key: QuestItemResource = null) -> void:
	if _key != null:
		original_key = _key
	
	if !original_key:
		return
	
	key = original_key._build_instance()
	ChestBus.chest_state_changed.emit(self)

func set_unlocked() -> void:
	key = null
	ChestBus.chest_state_changed.emit(self)

func set_trapped(_trap: Trap) -> void:
	trap = _trap
	ChestBus.chest_state_changed.emit(self)

func set_not_trapped() -> void:
	trap = null
	ChestBus.chest_state_changed.emit(self)
