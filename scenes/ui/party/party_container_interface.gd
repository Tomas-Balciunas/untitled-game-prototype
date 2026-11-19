extends Control

@onready var formation := [
	$PartyRow/Slot1/PartyMember,
	$PartyRow/Slot2/PartyMember,
	$PartyRow/Slot3/PartyMember,
	$PartyRow/Slot4/PartyMember,
]


func _ready() -> void:
	var minion_row := MinionRow.new()
	add_child(minion_row)
	minion_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	minion_row.grow_vertical = Control.GROW_DIRECTION_BEGIN

	SaveManager.connect("party_reloaded", Callable(self, "_on_party_reloaded"))
	PartyBus.party_member_added.connect(_on_member_added)
	_on_party_reloaded()

func _on_party_reloaded() -> void:
	for slot: PartyMemberSlot in formation:
		slot.hide_info()

	for slot_index in range(RunState.current.party.formation.size()):
		var member: Character = RunState.current.party.formation[slot_index]
		if member:
			_on_member_added(member, slot_index)

func _on_member_added(character: Character, slot_index: int) -> void:
	var character_ui: PartyMemberSlot = formation[slot_index]
	character_ui.bind(character)

func disable_targeting() -> void:
	for slot: PartyMemberSlot in formation:
		slot.disable_slot_targeting()

func enable_targeting() -> void:
	for slot: PartyMemberSlot in formation:
		slot.enable_slot_targeting()

func disable_party_ui() -> void:
	self.visible = false

func enable_party_ui() -> void:
	self.visible = true
