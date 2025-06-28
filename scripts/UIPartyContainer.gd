extends HBoxContainer

@onready var party: PartyManager
@onready var front_row = $PartyContainer/FrontRow
@onready var back_row = $PartyContainer/BackRow

const UIPartyMemberScene = preload("res://scenes/UIPartyMemberSlot.tscn")

func _ready():

	PartyManager.connect("member_added", Callable(self, "_on_member_added"))
	
	for i in PartyManager.members.size():
		_on_member_added(PartyManager.members[i], i)

func _on_member_added(character: CharacterInstance, index: int):
	var character_ui = UIPartyMemberScene.instantiate()
	character_ui.bind(character)
	
	if index < 3:
		front_row.add_child(character_ui)
	else:
		back_row.add_child(character_ui)
	
	character.connect("health_changed", Callable(character_ui, "_on_health_changed"))

#func _on_member_removed(character: CharacterInstance):
	#for child in get_children():
		#if child.character == character:
			#remove_child(child)
			#child.queue_free()
			#break
