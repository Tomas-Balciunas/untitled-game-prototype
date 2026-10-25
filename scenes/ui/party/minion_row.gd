extends HFlowContainer

class_name MinionRow

var _slots: Dictionary[Character, MinionSlot] = {}


func _ready() -> void:
	visible = false
	alignment = FlowContainer.ALIGNMENT_CENTER
	add_theme_constant_override("h_separation", 4)
	add_theme_constant_override("v_separation", 4)

	BattleBus.minion_added.connect(_on_minion_added)
	BattleBus.minion_removed.connect(_on_minion_removed)
	BattleBus.battle_end.connect(clear)


func _on_minion_added(minion: Character) -> void:
	if _slots.has(minion):
		return

	var slot := MinionSlot.new()
	add_child(slot)
	slot.bind(minion)
	_slots[minion] = slot
	visible = true


func _on_minion_removed(minion: Character) -> void:
	var slot: MinionSlot = _slots.get(minion)

	if slot == null:
		return

	_slots.erase(minion)
	slot.queue_free()
	visible = not _slots.is_empty()


func clear() -> void:
	for slot: MinionSlot in _slots.values():
		slot.queue_free()

	_slots.clear()
	visible = false
