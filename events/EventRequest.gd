extends RefCounted

class_name EventRequest

signal finished

var data: Variant
var subject: BaseCharacterResource = null
var completed: bool = false


func complete() -> void:
	completed = true
	finished.emit()
