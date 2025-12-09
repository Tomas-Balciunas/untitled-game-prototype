extends Item

class_name Gear

@export var base_stats: Stats
@export var modifiers: Array[StatModifier]
@export var effects: Array[Effect]

func _init() -> void:
	if not base_stats:
		base_stats = Stats.new()
