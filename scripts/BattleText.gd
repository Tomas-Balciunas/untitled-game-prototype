extends Node

var _text: Array[String] = []
var cont: RichTextLabel = null

func register_label(label: RichTextLabel) -> void:
	cont = label
	
func print_line(line: String) -> void:
	_text.append(line)
	print_text()
	
func print_text() -> void:
	if cont:
		cont.text = "\n".join(_text)
	else:
		push_error("battle text cont is null!")
