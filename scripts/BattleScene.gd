extends Node3D

class_name BattleScene

@onready var arena_root = $ArenaRoot
@onready var enemy_grid = $EnemyFormation
@onready var battle_ui = $BattleUI
@onready var battle_manager = $BattleManager

func _ready() -> void:
	battle_manager.enemy_grid = enemy_grid
	battle_manager.current_battler_change.connect(battle_ui._on_battler_change)
	battle_manager.turn_started.connect(battle_ui._on_turn_started)
	
	battle_ui.action_selected.connect(battle_manager._on_player_action_selected)
	
	battle_manager.enemy_died.connect(enemy_grid._on_enemy_died)

func initiate(arena: PackedScene, enemies: Array[CharacterResource], encounter_id: String):
	load_arena(arena)
	var enemy_instances = load_enemies(enemies)
	BattleContext.fill_context(battle_manager, enemy_grid, encounter_id)
	battle_manager.begin(enemy_instances)
	
func load_arena(arena_scene: PackedScene):
	for child in arena_root.get_children():
		child.queue_free()

	var arena_instance = arena_scene.instantiate()
	arena_root.add_child(arena_instance)

func load_enemies(enemies: Array[CharacterResource]) -> Array[CharacterInstance]:
	var enemy_instances = enemy_grid.get_enemy_instances(enemies)
	enemy_grid.place_all_enemies(enemy_instances)
	
	return enemy_instances
