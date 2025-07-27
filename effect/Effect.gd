extends Resource
class_name Effect

enum EffectCategory {
	PASSIVE,
	BUFF,
	DEBUFF,
	SKILL,
	STATUS,
	OTHER,
	TRAIT
}

@export var name: String = "Unnamed Effect"
@export var category: EffectCategory = EffectCategory.OTHER
@export var duration_turns: int = -1
var _connections := []  # { object, signal, id }
var _is_registered := false

var owner: CharacterInstance = null

func on_apply(_owner: CharacterInstance) -> void:
	owner = _owner
	_register_if_needed()

func on_expire(_owner: CharacterInstance) -> void:
	_unregister()

func prepare_for_battle(_owner: CharacterInstance) -> void:
	owner = _owner
	_register_if_needed()

func cleanup_after_battle() -> void:
	_unregister()
	owner = null

func _register_if_needed() -> void:
	if _is_registered:
		return
	_is_registered = true
	register_signals()

func _unregister() -> void:
	if not _is_registered:
		return
	for conn in _connections:
		if conn.object.is_connected(conn.signal, Callable(self, conn.method)):
			conn.object.disconnect(conn.signal, Callable(self, conn.method))
	_connections.clear()
	_is_registered = false

func register_signals() -> void:
	pass

func _bind(obj: Object, signal_name: String, method_name: String) -> void:
	var id = obj.connect(signal_name, Callable(self, method_name))
	_connections.append({ "object": obj, "signal": signal_name, "method": method_name })
