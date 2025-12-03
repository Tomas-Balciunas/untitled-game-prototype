extends Panel

@onready var party: PartyManager
@onready var formation := [
	[
		$PanelContainer/PartyContainer/FrontRow/PartyMemberSlot1/PartyMember,
		$PanelContainer/PartyContainer/FrontRow/PartyMemberSlot2/PartyMember,
		$PanelContainer/PartyContainer/FrontRow/PartyMemberSlot3/PartyMember
	],
 	[
		$PanelContainer/PartyContainer/BackRow/PartyMemberSlot1/PartyMember,
		$PanelContainer/PartyContainer/BackRow/PartyMemberSlot2/PartyMember,
		$PanelContainer/PartyContainer/BackRow/PartyMemberSlot3/PartyMember
	]
] 

const UIPartyMemberScene = preload("res://scenes/UIPartyMemberSlot.tscn")

func _ready() -> void:
	SaveManager.connect("party_reloaded", Callable(self, "_on_party_reloaded"))
	PartyBus.party_member_added.connect(_on_member_added)
	_on_party_reloaded()

func _on_party_reloaded() -> void:
	for row: Array in formation:
		for slot: PartyMemberSlot in row:
			slot.hide_info()

	for row_index in range(PartyManager.formation.size()):
		for slot_index in range(PartyManager.formation[row_index].size()):
			var member: CharacterInstance = PartyManager.formation[row_index][slot_index]
			if member:
				_on_member_added(member, row_index, slot_index)

func _on_member_added(character: CharacterInstance, row_index: int, slot_index: int) -> void:
	var character_ui: PartyMemberSlot = formation[row_index][slot_index]
	character_ui.bind(character)
	character.connect("mana_changed", Callable(character_ui, "_on_mana_changed"))

#func _on_member_removed(character: CharacterInstance):
	#for child in get_children():
		#if child.character == character:
			#remove_child(child)
			#child.queue_free()
			#break

func disable_targeting() -> void:
	for row: Array in formation:
		for slot: PartyMemberSlot in row:
			slot.disable_slot_targeting()

func enable_targeting() -> void:
	for row: Array in formation:
		for slot: PartyMemberSlot in row:
			slot.enable_slot_targeting()

func disable_party_ui() -> void:
	self.visible = false
	
func enable_party_ui() -> void:
	self.visible = true
