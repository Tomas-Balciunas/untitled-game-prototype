extends Node

signal battle_target_selected(target: CharacterInstance)
signal menu_skill_target_selected(target: CharacterInstance)

enum TargetType {
	SINGLE,
	BLAST,
	ADJACENT,
	ROW,
	COLUMN,
	MASS
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


func emit_selection(target: CharacterInstance) -> void:
	match mode:
		Mode.BATTLE:
			battle_target_selected.emit(target)
			end()
		Mode.MENU_SKILL:
			menu_skill_target_selected.emit(target)
	

func get_applicable_targets(target: CharacterInstance, type: TargetType) -> Array[CharacterInstance]:
	var is_party_member: bool = PartyManager.has_member(target.resource.id)
	var enemy_grid: EnemyFormation = BattleContext.enemy_grid
	var in_battle: bool = BattleContext.in_battle and enemy_grid != null
	
	match type:
		TargetType.SINGLE:
			return [target]
		TargetType.COLUMN:
			if is_party_member:
				return PartyManager.get_column_allies(target)
			if in_battle:
				return enemy_grid.get_column(target)
		TargetType.ROW:
			if is_party_member:
				return PartyManager.get_row_allies(target)
			if in_battle:
				return enemy_grid.get_row(target)
		TargetType.BLAST:
			if is_party_member:
				return PartyManager.get_blast_allies(target)
			if in_battle:
				return enemy_grid.get_blast(target)
		TargetType.ADJACENT:
			if is_party_member:
				return PartyManager.get_adjacent_allies(target)
			if in_battle:
				return enemy_grid.get_adjacent(target)
		TargetType.MASS:
			if is_party_member:
				return PartyManager.get_mass_allies()
			if in_battle:
				return enemy_grid.get_mass()
		#TODO: bounce targeting
	
	return [target]


func same_side(a: CharacterInstance, b: CharacterInstance) -> bool:
	var party: Array[CharacterInstance] = PartyManager.members
	
	return (a in party) == (b in party)
