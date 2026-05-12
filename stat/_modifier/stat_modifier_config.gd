extends RefCounted
class_name StatModifierConfig


const ADDITIVE_RANGES: Dictionary = {
	ItemTypes.Quality.POOR:        [1, 2],
	ItemTypes.Quality.COMMON:      [2, 3],
	ItemTypes.Quality.UNCOMMON:    [3, 5],
	ItemTypes.Quality.RARE:        [5, 8],
	ItemTypes.Quality.EXCEPTIONAL: [8, 10],
}

const MULTIPLICATIVE_RANGES: Dictionary = {
	ItemTypes.Quality.POOR:        [0.01, 0.02],
	ItemTypes.Quality.COMMON:      [0.02, 0.04],
	ItemTypes.Quality.UNCOMMON:    [0.04, 0.06],
	ItemTypes.Quality.RARE:        [0.06, 0.08],
	ItemTypes.Quality.EXCEPTIONAL: [0.08, 0.1],
}


static func get_range(_stat: Stats.StatRef, mod_type: StatModifier.Type, quality: ItemTypes.Quality) -> Array:
	match mod_type:
		StatModifier.Type.ADDITIVE: return ADDITIVE_RANGES[quality]
		StatModifier.Type.MULTIPLICATIVE: return MULTIPLICATIVE_RANGES[quality]
	push_error("stat_modifier_config: unknown modifier type %s" % mod_type)
	return []
