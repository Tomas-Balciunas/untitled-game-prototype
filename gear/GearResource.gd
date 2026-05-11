@abstract
extends ItemResource
class_name GearResource

enum Quality { POOR, COMMON, UNCOMMON, RARE, EXCEPTIONAL }
enum Type {
	WEAPON,
	CHEST,
	HELMET,
	BOOTS,
	GLOVES,
	RING,
	AMULET,
}

@export var base_stats: Stats
@export var modifiers: Array[StatModifier] = []
@export var effects: Array[Effect] = []
@export var quality: Quality = Quality.COMMON

@abstract
func get_applicable_stat_modifiers() -> Array[Stats.StatRef]

@abstract
func _build_instance() -> Variant


static func quality_to_string(q: Quality) -> String:
	match q:
		Quality.POOR:        return "Poor"
		Quality.COMMON:      return "Common"
		Quality.UNCOMMON:    return "Uncommon"
		Quality.RARE:        return "Rare"
		Quality.EXCEPTIONAL: return "Exceptional"
	return "Unknown"
