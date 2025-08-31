extends Node

var _text: Array[String] = []
var cont: RichTextLabel = null

func register_label(label: RichTextLabel):
	cont = label
	
func print_line(line: String):
	_text.append(line)
	print_text()
	
func print_text():
	if cont:
		cont.text = "\n".join(_text)
	else:
		push_error("battle text cont is null!")
