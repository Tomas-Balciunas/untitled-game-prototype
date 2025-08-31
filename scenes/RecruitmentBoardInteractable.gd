extends Interactable

var available_characters: Array = ["Alice"]

func _interact():
	print("Recruitable characters: ", available_characters)
