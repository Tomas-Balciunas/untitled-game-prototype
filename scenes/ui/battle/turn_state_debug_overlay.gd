extends CanvasLayer

class_name TurnStateDebugOverlay

const UPDATE_INTERVAL: float = 0.25

var _label: Label = null
var _timer: float = 0.0
var _active: bool = false


func _ready() -> void:
	layer = 100
	_label = Label.new()
	_label.position = Vector2(12, 12)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.text = "[Turn Debug — F3]"
	add_child(_label)
	visible = false

	BattleBus.battle_start.connect(_on_battle_start)
	BattleBus.battle_end.connect(_on_battle_end)


func _on_battle_start() -> void:
	_active = true
	visible = true


func _on_battle_end() -> void:
	_active = false
	visible = false


# Mirrors the map F3 overlay; map overlay is process-disabled in battle so no conflict.
func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visible = not visible


func _process(delta: float) -> void:
	if not visible:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = UPDATE_INTERVAL
	_refresh()


func _refresh() -> void:
	var lines: Array = ["[Turn Debug — F3]"]

	var manager: BattleManager = BattleContext.manager
	if manager == null:
		lines.append("No battle manager")
		_label.text = "\n".join(lines)
		return

	lines.append("State: %s" % BattleManager.BattleState.keys()[manager.current_state])

	var battler: Character = manager.current_battler
	lines.append("Battler: %s" % (battler.resource.name if battler else "-"))

	var ts: TurnState = manager.turn_state
	if ts:
		lines.append("AP: %d" % ts.action_points)
		lines.append("Attacks: %d" % ts.active_attack_count)
		lines.append("Hits: %d" % ts.damage_instance_count)
		lines.append("Damage dealt: %d" % ts.damage_dealt)
		lines.append("Healing done: %d" % ts.healing_done)
	else:
		lines.append("No turn state")

	var queue: Array = manager.turn_queue
	if queue.size() > 0:
		var names: Array = []
		for c: Character in queue:
			names.append(c.resource.name)
		lines.append("Queue: %s" % ", ".join(names))

	lines.append("FPS: %d" % int(Engine.get_frames_per_second()))
	_label.text = "\n".join(lines)
