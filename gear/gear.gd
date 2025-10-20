extends Item

class_name Gear

@export var base_stats: Dictionary = Stats.STATS

@export var modifiers: Array[StatModifier]
@export var effects: Array[Effect]

func instantiate() -> GearInstance:
	var inst := GearInstance.new(self)
	inst.template = self
	return inst
