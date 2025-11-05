extends Area3D
class_name Triggerable

signal triggered(data: Dictionary)

@export var trigger_once: bool = true
var _triggered := false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	if trigger_once and _triggered:
		return
	
	_triggered = true
	_fire({"body": body})

func _fire(data: Dictionary) -> void:
	emit_signal("triggered", data)
