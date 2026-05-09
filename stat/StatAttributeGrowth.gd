extends Resource

class_name StatAttributeGrowth

@export var entries: Array[StatGrowthEntry] = []

func _init() -> void:
	if entries.is_empty():
		for stat: Stats.StatRef in Stats.StatRef.values():
			var entry := StatGrowthEntry.new()
			entry.stat = stat
			entries.append(entry)

func get_contribution(stat: Stats.StatRef, attributes: Attributes) -> float:
	var total: float = 0.0

	for entry: StatGrowthEntry in entries:
		if entry.stat != stat:
			continue
		for mult: AttributeMultiplier in entry.contributions:
			if mult.multiplier == 0.0:
				continue
			total += attributes.get_attribute(mult.attribute) * mult.multiplier

	return total
