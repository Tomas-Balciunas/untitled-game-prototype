extends Node
class_name StatModifierConfig


const ADDITIVE_RANGES: Dictionary = {
	GearResource.Quality.POOR:        [1, 2],
	GearResource.Quality.COMMON:      [2, 3],
	GearResource.Quality.UNCOMMON:    [3, 5],
	GearResource.Quality.RARE:        [5, 8],
	GearResource.Quality.EXCEPTIONAL: [8, 10],
}

const MULTIPLICATIVE_RANGES: Dictionary = {
	GearResource.Quality.POOR:        [0.01, 0.02],
	GearResource.Quality.COMMON:      [0.02, 0.04],
	GearResource.Quality.UNCOMMON:    [0.04, 0.06],
	GearResource.Quality.RARE:        [0.06, 0.08],
	GearResource.Quality.EXCEPTIONAL: [0.08, 0.1],
}


static func get_range(_stat: Stats.StatRef, mod_type: StatModifier.Type, quality: GearResource.Quality) -> Array:
	match mod_type:
		StatModifier.Type.ADDITIVE:       return ADDITIVE_RANGES[quality]
		StatModifier.Type.MULTIPLICATIVE: return MULTIPLICATIVE_RANGES[quality]
	push_error("stat_modifier_config: unknown modifier type %s" % mod_type)
	return []
