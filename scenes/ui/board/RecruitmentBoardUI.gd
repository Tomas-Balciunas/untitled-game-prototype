extends PanelContainer

@onready var list: VBoxContainer = $List
const RecruitmentItem = preload("res://scenes/ui/board/recruitment_item.tscn")



func bind(characters: Array[CharacterResource]) -> void:
	#list.queue_free()
	for chara in characters:
		var item := RecruitmentItem.instantiate()
		list.add_child(item)
		item.bind(chara)
		


func _on_close_pressed() -> void:
	self.queue_free()
