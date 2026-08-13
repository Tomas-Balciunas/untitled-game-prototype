extends StatModifier
class_name atktohp

func compute_value(c: Character, _ds: float) -> float:
	return c.modified_stats.attack * value

func get_description() -> String:
	return "Converts %s%% of atk into hp" % int(round(100 * value))
