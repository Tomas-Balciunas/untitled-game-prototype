extends Panel

@onready var party: PartyManager
@onready var formation := [
	$PanelContainer/PartyContainer/PartyRow/PartyMemberSlot1/PartyMember,
	$PanelContainer/PartyContainer/PartyRow/PartyMemberSlot2/PartyMember,
	$PanelContainer/PartyContainer/PartyRow/PartyMemberSlot3/PartyMember,
	$PanelContainer/PartyContainer/PartyRow/PartyMemberSlot4/PartyMember,
]


func _ready() -> void:
	SaveManager.connect("party_reloaded", Callable(self, "_on_party_reloaded"))
	PartyBus.party_member_added.connect(_on_member_added)
	_on_party_reloaded()

func _on_party_reloaded() -> void:
	for slot: PartyMemberSlot in formation:
		slot.hide_info()

	for slot_index in range(PartyManager.formation.size()):
		var member: CharacterInstance = PartyManager.formation[slot_index]
		if member:
			_on_member_added(member, slot_index)

func _on_member_added(character: CharacterInstance, slot_index: int) -> void:
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
