extends Node
class_name StatModifierConfig



const RAND_RANGE_VALUES: Dictionary = {
	Stats.StatRef.ATTACK: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	},
	Stats.StatRef.SP: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	},
	Stats.StatRef.HEALTH: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	},
	Stats.StatRef.MANA: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	},
	Stats.StatRef.SPEED: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	},
	Stats.StatRef.DEFENSE: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	},
	Stats.StatRef.MAGIC_POWER: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	},
	Stats.StatRef.DIVINE_POWER: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	},
	Stats.StatRef.MAGIC_DEFENSE: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	},
	Stats.StatRef.RESISTANCE: {
		StatModifier.Type.ADDITIVE: {
			Gear.Quality.POOR: [1, 2],
			Gear.Quality.COMMON: [2, 3],
			Gear.Quality.UNCOMMON: [3, 5],
			Gear.Quality.RARE: [5, 8],
			Gear.Quality.EXCEPTIONAL: [8, 10],
		},
		StatModifier.Type.MULTIPLICATIVE: {
			Gear.Quality.POOR: [0.01, 0.02],
			Gear.Quality.COMMON: [0.02, 0.04],
			Gear.Quality.UNCOMMON: [0.04, 0.06],
			Gear.Quality.RARE: [0.06, 0.08],
			Gear.Quality.EXCEPTIONAL: [0.08, 0.1],
		}
	}
}
