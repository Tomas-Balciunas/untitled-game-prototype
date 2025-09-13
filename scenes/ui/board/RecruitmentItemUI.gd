extends HBoxContainer

@onready var name_label: Label = $Name
@onready var hire_btn: Button = $Hire

var hiree: CharacterResource = null

func bind(character: CharacterResource):
	name_label.text = character.name
	hiree = character
	for member in PartyManager.members:
		if member.resource.id == hiree.id:
			hire_btn.disabled = true

func _on_hire_pressed() -> void:
	PartyManager.add_member(hiree)
	hire_btn.disabled = true
