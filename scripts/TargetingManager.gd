extends Node

signal battle_target_selected(target: Character)
signal menu_skill_target_selected(target: Character)

enum TargetType {
	SINGLE,
	BLAST,
	ADJACENT,
	ROW,
	COLUMN,
	MASS,
	BOUNCE,
	SALVO
}

enum TargetState {
	LIVING,
	DEAD,
	ANY
}

enum Mode {
	DISABLED,
	NONE,
	BATTLE,
	MENU_SKILL
}

var mode: Mode = Mode.NONE


func begin(_mode: Mode) -> void:
	set_mode(_mode)


func end() -> void:
	mode = Mode.NONE


func set_mode(_mode: Mode) -> void:
	mode = _mode


func emit_selection(target: Character) -> void:
	match mode:
		Mode.BATTLE:
			battle_target_selected.emit(target)
		Mode.MENU_SKILL:
			menu_skill_target_selected.emit(target)
	end()
	

func is_player_side(c: Character) -> bool:
	var battle: BattleSession = RunState.current.battle

	if battle.in_battle and battle.manager:
		return battle.manager.is_player_side(c)

	return RunState.current.party.has_member_by_object(c)


func get_applicable_targets(target: Character, type: TargetType) -> Array[Character]:
	var party: Party = RunState.current.party
	var player_side: bool = is_player_side(target)
	var in_party: bool = party.has_member_by_object(target)
	var enemy_grid: EnemyFormation = RunState.current.battle.enemy_formation
	var in_battle: bool = RunState.current.battle.in_battle and enemy_grid != null

	match type:
		TargetType.SINGLE:
			return [target]
		TargetType.COLUMN:
			if player_side:
				return party.get_column_allies(target)
			if in_battle:
				return enemy_grid.get_column(target)
		TargetType.ROW:
			if player_side:
				return _player_side_all()
			if in_battle:
				return enemy_grid.get_row(target)
		TargetType.BLAST:
			if in_party:
				return party.get_blast_allies(target)
			if player_side:
				return [target]
			if in_battle:
				return enemy_grid.get_blast(target)
		TargetType.ADJACENT:
			if in_party:
				return party.get_adjacent_allies(target)
			if player_side:
				return [target]
			if in_battle:
				return enemy_grid.get_adjacent(target)
		TargetType.MASS:
			if player_side:
				return _player_side_all()
			if in_battle:
				return enemy_grid.get_mass()
		#TODO: bounce targeting

	return [target]


func _player_side_all() -> Array[Character]:
	var all: Array[Character] = RunState.current.party.get_mass_allies()
	var battle: BattleSession = RunState.current.battle

	if battle.in_battle and battle.manager:
		all.append_array(battle.manager.minions)

	return all


func matches_state(kind: TargetState, c: Character) -> bool:
	if c == null:
		return false

	match kind:
		TargetState.LIVING:
			return not c.is_dead
		TargetState.DEAD:
			return c.is_dead
		_:
			return true


func same_side(a: Character, b: Character) -> bool:
	return is_player_side(a) == is_player_side(b)
