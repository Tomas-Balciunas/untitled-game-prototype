extends Interactable
class_name DoorInteractable

const HIGHLIGHT_COLOR := Color(0.88, 0.588, 0.88)
const LOCKED_TINT := Color(0.62, 0.60, 0.56)

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var blocker: CollisionShape3D = $StaticBody3D/CollisionShape3D2
@onready var leaf: Node3D = animation_player.get_parent()

@export var door: Door = null
@export var door_id: String = ""
@export var locked: bool = false
@export var key_id: String = ""
@export var key_name: String = ""
@export var seal_name: String = ""
@export var trap_id: String = ""

var _highlight_meshes: Array = []
var _base_albedo: Dictionary = {}

func _ready() -> void:
	super._ready()

	_highlight_meshes = find_children("", "MeshInstance3D", true, false)

	for mesh: MeshInstance3D in _highlight_meshes:
		if not mesh.material_override:
			mesh.material_override = StandardMaterial3D.new()

		_base_albedo[mesh] = mesh.material_override.albedo_color

	_build_door()
	_apply_lock_visual(door.key != null)

	if not door_id.is_empty():
		name = door_id

	ObjectBus.door_unlocked.connect(_on_door_unlocked)
	ObjectBus.door_state_changed.connect(_on_door_state_changed)

func _build_door() -> void:
	door = door.duplicate() if door != null else Door.new()

	if not door_id.is_empty():
		door.id = door_id

	if locked:
		door.key = KeyFactory.rebuild(key_id, key_name)
		door.key_id = key_id
		door.key_name = key_name
		door.seal_name = seal_name

	if not trap_id.is_empty():
		door.trap = TrapRegistry.instantiate_trap(trap_id)

func on_map_loaded(_map_data: Dictionary) -> void:
	if door_id.is_empty():
		return

	var state: Dictionary = MapInstance.get_door_state(door_id)

	if state.is_empty():
		_store()
		return

	var still_locked: bool = state.get("locked", false)
	var saved_trap: String = state.get("trap_id", "")

	door.key = KeyFactory.rebuild(state.get("key_id", ""), state.get("key_name", "")) if still_locked else null
	door.key_id = state.get("key_id", "")
	door.key_name = state.get("key_name", "")
	door.seal_name = state.get("seal_name", "")
	door.was_locked = state.get("was_locked", false)
	door.trap = TrapRegistry.instantiate_trap(saved_trap) if not saved_trap.is_empty() else null

	_apply_lock_visual(still_locked)
	apply_restored_state(state.get("open", false))

func _interact() -> void:
	if GameState.is_busy():
		return

	if door == null:
		door = Door.new()

	if door.key != null or door.trap != null:
		ObjectBus.open_door_requested.emit(door)
		return

	if !door.is_open:
		_open()
	else:
		_close()

func _open() -> void:
	animation_player.play("open")
	door.is_open = true
	_set_blocking(false)
	ObjectBus.door_state_changed.emit(door)

func _close() -> void:
	animation_player.play("close")
	door.is_open = false
	_set_blocking(true)
	ObjectBus.door_state_changed.emit(door)

func _set_blocking(blocking: bool) -> void:
	blocker.disabled = not blocking

func apply_restored_state(is_open: bool) -> void:
	if door == null:
		return

	door.is_open = is_open
	leaf.rotation = Vector3(0, PI * 0.5, 0) if is_open else Vector3.ZERO
	_set_blocking(not is_open)

func _apply_lock_visual(is_locked: bool) -> void:
	var tint := LOCKED_TINT if is_locked else Color.WHITE

	for mesh: MeshInstance3D in _highlight_meshes:
		mesh.material_override.albedo_color = tint
		_base_albedo[mesh] = tint

func _on_door_unlocked(unlocked: Door) -> void:
	if door == null or unlocked != door:
		return

	_apply_lock_visual(false)
	_open()

func _on_door_state_changed(changed: Door) -> void:
	if door == null or changed != door:
		return

	_store()

func _store() -> void:
	if door_id.is_empty():
		return

	MapInstance.set_door_state(door_id, {
		"open": door.is_open,
		"locked": door.key != null,
		"key_id": door.key_id,
		"key_name": door.key_name,
		"seal_name": door.seal_name,
		"trap_id": door.trap.id if door.trap else "",
		"was_locked": door.was_locked,
	})

func _set_highlight(enable: bool) -> void:
	for mesh: MeshInstance3D in _highlight_meshes:
		mesh.material_override.albedo_color = HIGHLIGHT_COLOR if enable else _base_albedo.get(mesh, Color.WHITE)
