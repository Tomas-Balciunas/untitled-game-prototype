extends Interactable

class_name CharacterInteractable

var character: CharacterInstance = null

func _interact():
	if !character:
		push_error("Character not assigned to character interactable!")
	
	print("interacted with %s" % character.resource.name)

func set_character(char: CharacterInstance):
	character = char
