extends RefCounted

const RES := "res://characters/allies/Coura/Coura.tres"

static func make() -> Character:
	return Character.new(load(RES).duplicate(true))

static func free_built(chars: Array) -> void:
	for c in chars:
		if c and is_instance_valid(c.state):
			c.state.free()
