extends Node

class_name ActionEvent

signal confirmed_signal

var confirmed: bool = false

func confirm():
	if confirmed:
		return
	
	confirmed = true
	confirmed_signal.emit()
