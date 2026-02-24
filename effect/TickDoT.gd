extends RefCounted

class_name TickDoT


var target: CharacterInstance = null
var tick_power: float = 1.0
var should_consume_duration: bool = true


func _init(_target: CharacterInstance) -> void:
	target = _target


func set_tick_power(power: float) -> void:
	tick_power = power


func set_duration_consumption(should_consume: bool) -> void:
	should_consume_duration = should_consume


func execute() -> void:
	for effect in target.effects:
		effect.tick()
