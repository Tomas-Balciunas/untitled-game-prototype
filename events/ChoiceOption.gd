extends Resource
class_name ChoiceOption

@export var id: String = ""
@export var btn_text: String = ""


static func make(p_id: String, p_btn_text: String) -> ChoiceOption:
	var c := ChoiceOption.new()
	c.id = p_id
	c.btn_text = p_btn_text
	return c
