extends PanelContainer

class_name MinionSlot

const SLOT_SIZE := Vector2(150, 24)
const DEAD_TINT := Color(0.45, 0.45, 0.45)
const ACTIVE_TINT := Color(0.8, 0.8, 0.4)
const HOVER_COLOR := Color(0.737255, 0.364706, 0.364706, 0.337255)

var character_instance: Character

var _name_label: Label
var _hp_label: Label
var _hover_overlay: ColorRect
var _active := false


func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style := StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	style.set_border_width_all(1)
	style.border_color = Color.WHITE
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	_name_label = Label.new()
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.clip_text = true
	_name_label.add_theme_font_size_override("font_size", 12)
	row.add_child(_name_label)

	_hp_label = Label.new()
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_label.add_theme_font_size_override("font_size", 12)
	row.add_child(_hp_label)

	_hover_overlay = ColorRect.new()
	_hover_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_overlay.color = HOVER_COLOR
	_hover_overlay.visible = false
	add_child(_hover_overlay)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	CharacterBus.stat_changed.connect(_on_stat_changed)
	BattleBus.turn_started.connect(_on_turn_started)
	BattleBus.turn_ended.connect(_on_turn_ended)


func bind(character: Character) -> void:
	character_instance = character
	_name_label.text = character.name
	character.died.connect(_on_life_changed)
	character.revived.connect(_on_life_changed)
	_refresh()


func _refresh() -> void:
	var max_health: int = character_instance.stats.get_stat(Stats.StatRef.HEALTH)
	_hp_label.text = "%d/%d" % [character_instance.state.current_health, max_health]
	_apply_tint()


func _apply_tint() -> void:
	if character_instance and character_instance.is_dead:
		modulate = DEAD_TINT
	elif _active:
		modulate = ACTIVE_TINT
	else:
		modulate = Color.WHITE


func _on_stat_changed(who: Character, stat: Stats.StatRef) -> void:
	if who == character_instance and stat == Stats.StatRef.HEALTH:
		_refresh()


func _on_life_changed(_c: Character) -> void:
	_refresh()


func _on_turn_started(battler: Character, _is_player_side: bool) -> void:
	_active = battler == character_instance
	_apply_tint()


func _on_turn_ended() -> void:
	_active = false
	_apply_tint()


func _on_mouse_entered() -> void:
	_hover_overlay.visible = RunState.current.battle.ally_targeting_enabled


func _on_mouse_exited() -> void:
	_hover_overlay.visible = false


func _can_target() -> bool:
	var battle: BattleSession = RunState.current.battle

	if TargetingManager.mode != TargetingManager.Mode.BATTLE or not battle.ally_targeting_enabled:
		return false

	var manager: BattleManager = battle.manager

	if manager == null or manager.turn_state == null or manager.turn_state.current_action == null:
		return false

	return TargetingManager.matches_state(manager.turn_state.current_action.get_target_state(), character_instance)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton

	if click == null or not click.pressed:
		return

	if click.button_index == MOUSE_BUTTON_RIGHT:
		CharacterBus.display_status_effects.emit(character_instance)
	elif click.button_index == MOUSE_BUTTON_LEFT and _can_target():
		TargetingManager.emit_selection(character_instance)
