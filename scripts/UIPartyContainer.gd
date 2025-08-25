extends Panel

@onready var party: PartyManager
var character_menu: CharacterMenu = null
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
const CharacterMenuScene = preload("res://scenes/ui/character/CharacterMenu.tscn")

func _ready():
	SaveManager.connect("party_reloaded", Callable(self, "_on_party_reloaded"))
	PartyManager.connect("member_added", Callable(self, "_on_member_added"))
	
	character_menu = CharacterMenuScene.instantiate()
	character_menu.hide()
	get_tree().root.add_child.call_deferred(character_menu)

func _on_party_reloaded():
	for row in formation:
		for slot in row:
			slot.hide_info()

	for row_index in range(PartyManager.formation.size()):
		for slot_index in range(PartyManager.formation[row_index].size()):
			var member = PartyManager.formation[row_index][slot_index]
			if member:
				_on_member_added(member, row_index, slot_index)

func _on_member_added(character: CharacterInstance, row_index: int, slot_index: int):
	var character_ui = formation[row_index][slot_index]
	character_ui.bind(character)
	character_ui.show()
	
	character.connect("health_changed", Callable(character_ui, "_on_health_changed"))
	character.connect("mana_changed", Callable(character_ui, "_on_mana_changed"))
	character_ui.connect("open_character_menu_requested", Callable(self, "_on_open_character_menu_requested"))

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

func disable_party_ui():
	self.visible = false
	
func enable_party_ui():
	self.visible = true

func highlight_member(character: CharacterInstance):
	for row in formation:
		for slot in row:
			if slot.character_instance == character:
				slot.highlight()
			else:
				slot.unhighlight()

func clear_highlights():
	for row in formation:
		for slot in row:
			slot.unhighlight()

func _on_open_character_menu_requested(character_instance: CharacterInstance):
	character_menu.bind(character_instance)
	character_menu.show()
