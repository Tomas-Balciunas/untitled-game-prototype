extends Item

class_name Gear

@export var base_stats: Stats
@export var modifiers: Array[StatModifier]
@export var effects: Array[Effect]
@export var tier: String = "CUSTOM"
@export var is_random := false
@export var max_modifiers: int = 2
@export var max_effects: int = 2

func _init() -> void:
	if not base_stats:
		base_stats = Stats.new()

func instantiate() -> GearInstance:
	var inst := GearInstance.new(self)
	inst.template = self
	return inst
