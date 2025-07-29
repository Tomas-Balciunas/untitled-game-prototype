extends Node

signal map_transition_started(id: String)
signal map_transition_ended()

func transit_to_map_start(id: String):
	if GameState.is_busy():
		return
	GameState.current_state = GameState.States.MAP_TRANSITION
	emit_signal("map_transition_started", id)

func transit_to_map_end():
	emit_signal("map_transition_ended")
	GameState.current_state = GameState.States.IDLE
