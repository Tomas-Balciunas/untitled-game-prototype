extends Node

## Owns the current Run. The only global handle to run-scoped data.
## `current` is set at declaration, not in _ready, so it exists before any
## other autoload's _ready runs.

var current: Run = Run.new()


func begin() -> void:
	current = Run.new()

func load_from(state: Dictionary) -> void:
	current = Run.new()
	current.game_load(state)
