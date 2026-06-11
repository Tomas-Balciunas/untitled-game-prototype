extends Node

signal party_reloaded

const SAVE_PATH := "user://save_slot_%d.save"
const SAVE_VERSION := 1

# Issues collected during the last load (missing effects/skills/characters).
var load_issues: Array[String] = []

func save_game(slot: int) -> void:
	var game_state := build_game_state()
	var final_path := SAVE_PATH % slot
	var tmp_path := final_path + ".tmp"

	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		push_error("Save failed: cannot open %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())])
		return
	file.store_var(game_state)
	file.close()

	# The old save is only removed once the new one is fully written, so a
	# crash mid-save can't destroy the slot.
	var dir := DirAccess.open("user://")
	if dir.file_exists(final_path):
		dir.remove(final_path)
	var err := dir.rename(tmp_path, final_path)
	if err != OK:
		push_error("Save failed: cannot move %s into place (%s)" % [tmp_path, error_string(err)])
		return
	print("Game saved to slot %d" % slot)

func load_game(slot: int) -> Dictionary:
	var path := SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		# A crash between writing the tmp file and the swap leaves only the tmp.
		if FileAccess.file_exists(path + ".tmp"):
			path += ".tmp"
			push_warning("Recovering save slot %d from temp file" % slot)
		else:
			print("No save file in slot %d" % slot)
			return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var data: Variant = file.get_var()
	file.close()
	if data is not Dictionary:
		push_warning("Save slot %d is corrupted, ignoring" % slot)
		return {}
	return data

func build_game_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"game_state": GameState.game_save(),
		"party": PartyManager.game_save(),
		"dungeon": MapInstance.game_save(),
		"interaction_state": InteractionTagManager.game_save(),
	}

func apply_game_state(state: Dictionary) -> void:
	load_issues.clear()
	_migrate(state)
	if state.has("game_state"):
		GameState.game_load(state["game_state"])
	if state.has("party"):
		PartyManager.game_load(state["party"])
	if state.has("dungeon"):
		MapInstance.game_load(state["dungeon"])
	if state.has("interaction_state"):
		InteractionTagManager.game_load(state["interaction_state"])
	emit_signal("party_reloaded")
	if not load_issues.is_empty():
		print("Save loaded with %d issue(s) — see warnings above" % load_issues.size())

# Loaders call this instead of failing silently; issues are collected per load
# so they can later be surfaced in the UI.
func report_load_issue(msg: String) -> void:
	load_issues.append(msg)
	push_warning(msg)

func _migrate(state: Dictionary) -> void:
	var version: int = state.get("version", 0)
	while version < SAVE_VERSION:
		match version:
			0:
				_migrate_v0_to_v1(state)
		version += 1
	state["version"] = version

# v0 (unversioned) saves have the same layout as v1 — the bump just stamps them.
func _migrate_v0_to_v1(_state: Dictionary) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quicksave"):
		save_game(0)
	if event.is_action_pressed("quickload"):
		var state := load_game(0)
		if state.size() > 0:
			apply_game_state(state)
