extends Node

class_name ActionEvent

signal confirmed_signal

var confirmed: bool = false
var finished: bool = false
var info: String = ""

func _init(t: String = "") -> void:
	info = t

func confirm() -> void:
	if confirmed:
		return
	
	confirmed = true
	confirmed_signal.emit()

func finish() -> void:
	finished = true
