extends Node

signal map_transition_started(id: String)
signal map_transition_ended()

func transit_to_map_start(id: String) -> void:
	if GameState.is_busy():
		return
	GameState.current_state = GameState.States.MAP_TRANSITION
	emit_signal("map_transition_started", id)

func transit_to_map_end() -> void:
	emit_signal("map_transition_ended")
	GameState.current_state = GameState.States.IDLE
