extends Node

class_name ActionEvent

signal confirmed_signal

var confirmed: bool = false
var finished: bool = false

func confirm() -> void:
	if confirmed:
		return
	
	confirmed = true
	confirmed_signal.emit()

func finish() -> void:
	finished = true
