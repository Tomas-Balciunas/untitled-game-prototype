extends Resource
class_name Effect

const ActivationScope = EffectTriggers.ActivationScope

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
@export var activation_scope: ActivationScope = ActivationScope.OWNER_ONLY 
@export var duration_turns: int = -1
#@export_enum(
	#"on_turn_end",
	#"on_turn_start",
	#"on_hit",
	#"on_post_hit",
	#"damage_about_to_be_applied",
	#"on_before_receive_damage",
	#"damage_applied",
	#"on_expire",
	#"on_apply_effect",
	#"on_heal",
	#"on_receive_heal"
#) var trigger: String = "on_turn_end"
var _connections := []
var _is_registered := false

var owner: CharacterInstance = null
var _is_runtime_instance := false

func on_apply(_owner: CharacterInstance) -> void:
	_is_runtime_instance = true
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

func _unregister() -> void:
	if not _is_registered:
		return
	#for conn in _connections:
		#if conn.object.is_connected(conn.signal, Callable(self, conn.method)):
			#conn.object.disconnect(conn.signal, Callable(self, conn.method))
	#_connections.clear()
	_is_registered = false

#func register_signals() -> void:
	#pass

#func _bind(obj: Object, signal_name: String, method_name: String) -> void:
	#var _id = obj.connect(signal_name, Callable(self, method_name))
	#_connections.append({ "object": obj, "signal": signal_name, "method": method_name })

#func applies_to_context(trigger: String, ctx: ActionContext = null) -> bool:
	#return true
