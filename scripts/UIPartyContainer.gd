extends Panel

@onready var party: PartyManager
@onready var formation = [
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

func _ready():
	PartyManager.connect("member_added", Callable(self, "_on_member_added"))
	
	for row_index in range(PartyManager.formation.size()):
		if not PartyManager.formation[row_index]:
			continue
		for slot_index in range(PartyManager.formation[row_index].size()):
			if not PartyManager.formation[row_index][slot_index]:
				var slot: PartyMemberSlot = formation[row_index][slot_index]
				slot.hide_info()
				continue
			_on_member_added(PartyManager.formation[row_index][slot_index], row_index, slot_index)

func _on_member_added(character: CharacterInstance, row_index: int, slot_index: int):
	var character_ui = formation[row_index][slot_index]
	character_ui.bind(character)
	character_ui.show()
	
	character.connect("health_changed", Callable(character_ui, "_on_health_changed"))

#func _on_member_removed(character: CharacterInstance):
	#for child in get_children():
		#if child.character == character:
			#remove_child(child)
			#child.queue_free()
			#break

func disable_targeting():
	for row in formation:
		for slot in row:
			slot.disable_slot_targeting()

func enable_targeting():
	for row in formation:
		for slot in row:
			slot.enable_slot_targeting()
