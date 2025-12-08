extends Node
class_name CharacterState

var current_health: int = 0
var current_mana: int = 0
var current_sp: int = 0

var modifiers: Array[StatModifier] = []
var temporary_modifiers: Array[StatModifier] = []

func _init(stats: Stats) -> void:
	current_health = int(stats.health)
	current_mana = int(stats.mana)
	current_sp = int(stats.sp)


func get_modifiers() -> Array[StatModifier]:
	return modifiers + temporary_modifiers

func add_modifier(m: StatModifier) -> void:
	modifiers.append(m)

func add_temporary_modifier(m: StatModifier) -> void:
	temporary_modifiers.append(m)

func remove_modifier(m: StatModifier) -> void:
	modifiers.erase(m)
	
func remove_temporary_modifier(m: StatModifier) -> void:
	temporary_modifiers.erase(m)
