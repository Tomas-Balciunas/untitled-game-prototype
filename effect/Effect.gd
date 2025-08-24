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
@export var description: String = "Unnamed Effect"
@export var category: EffectCategory = EffectCategory.OTHER
@export var duration_turns: int = -1

var _is_registered := false
var _is_instance := false
var owner: CharacterInstance = null
var _is_runtime_instance := false

func set_source(source: CharacterInstance):
	pass
	
func listened_triggers() -> Array:
	return []
	
func can_process(event: TriggerEvent) -> bool:
	return false

func get_description() -> String:
	return description

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
	_is_registered = false
