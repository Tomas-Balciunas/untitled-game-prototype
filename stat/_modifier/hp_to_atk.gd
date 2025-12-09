extends StatModifier
class_name hptoatk

func compute_value(c: CharacterInstance, _ds: float) -> float:
	return c.computed_stats.health * value

func get_description() -> String:
	return "Converts %s%% of hp into attack power" % int(round(100 * value))
