extends RefCounted

class_name BattleScanEntry

var battler: Character
var tags: Array[String] = []

func _init(_battler) -> void:
	battler = _battler
