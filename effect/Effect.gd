@abstract
extends Resource
class_name Effect

enum EffectCategory {
	PASSIVE,
	BUFF,
	DEBUFF,
	CONTROL
}

@export var id: String
@export var name: String = "Unnamed Effect"
@export var description: String = "Unnamed Effect"
@export var category: EffectCategory = EffectCategory.PASSIVE
@export var duration_turns: int = -1
@export var single_trigger: bool = false

@export var _stackable := false
var _is_registered := false
var _is_instance := false
var owner: CharacterInstance = null
var _is_runtime_instance := false
@export var _should_append := true
@export var is_battle_only := false

func set_source(_source: CharacterInstance) -> void:
	pass
	
func listened_triggers() -> Array:
	return []
	
func can_process(_event: TriggerEvent) -> bool:
	return false
	
func on_trigger(_event: TriggerEvent) -> void:
	pass

func _get_name() -> String:
	return name

func get_description() -> String:
	return description

func on_apply(_owner: CharacterInstance) -> void:
	_is_runtime_instance = true
	owner = _owner
	_register_if_needed()

func on_expire() -> void:
	_unregister()

func prepare_for_battle(_owner: CharacterInstance) -> void:
	owner = _owner
	_register_if_needed()

func _register_if_needed() -> void:
	if _is_registered:
		return
	_is_registered = true

func _unregister() -> void:
	if not _is_registered:
		return
	_is_registered = false

func _is_stackable() -> bool:
	return _stackable

func should_append() -> bool:
	return _should_append

func remove_self() -> void:
	owner.remove_effect(self)
	
func get_is_instance() -> bool:
	return _is_instance
