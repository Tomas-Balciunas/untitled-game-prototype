extends Node

var _text: Array[String] = []
var cont: RichTextLabel = null

func register_label(label: RichTextLabel) -> void:
	cont = label
	
func print_line(line: String) -> void:
	_text.append(line)
	
	if len(_text) > 100:
		_text.pop_front()
	
	print_text()
	
func print_text() -> void:
	if cont:
		cont.text = "\n".join(_text)
	else:
		push_error("battle text cont is null!")
