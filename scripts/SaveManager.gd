extends Node

signal party_reloaded

const SAVE_PATH := "user://save_slot_%d.save"

func save_game(slot: int) -> void:
	var game_state := build_game_state()
	var file := FileAccess.open(SAVE_PATH % slot, FileAccess.WRITE)
	if file:
		file.store_var(game_state)
		file.close()
		print("Game saved to slot %d" % slot)

func load_game(slot: int) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH % slot):
		print("No save file in slot %d" % slot)
		return {}
		
	var file := FileAccess.open(SAVE_PATH % slot, FileAccess.READ)
	var data: Dictionary = file.get_var()
	file.close()
	return data

func build_game_state() -> Dictionary:
	return {
		"party": PartyManager.to_dict(),
		"dungeon": MapInstance.to_dict(),
		"interaction_state": InteractionTagManager.game_save()
	}

func apply_game_state(state: Dictionary) -> void:
	if state.has("party"):
		PartyManager.from_dict(state["party"])
	if state.has("dungeon"):
		MapInstance.from_dict(state["dungeon"])
		#Dungeon.load_map(state["dungeon"]["dungeon"]["id"], state["dungeon"])
	if state.has("interaction_state"):
		InteractionTagManager.game_load(state["interaction_state"])
	emit_signal("party_reloaded")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quicksave"):
		save_game(0)
	if event.is_action_pressed("quickload"):
		var state := load_game(0)
		if state.size() > 0:
			apply_game_state(state)
