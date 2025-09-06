extends Interactable

var available_characters: Array = ["a_coura_1", "0000"]
var characters: Array[CharacterResource] = []
const RecruitmentBoard = preload("res://scenes/ui/board/recruitment_board.tscn")

func _interact():
	characters = []
	for id in available_characters:
		characters.append(CharacterRegistry.get_character(id))
		
	var board = RecruitmentBoard.instantiate()
	get_tree().root.add_child(board)
	board.bind(characters)
	
	
