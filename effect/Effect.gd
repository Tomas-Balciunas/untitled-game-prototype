@abstract
extends Resource
class_name Effect

enum EffectCategory {
	PASSIVE,
	BUFF,
	DEBUFF,
	STATUS,
	CONTROL,
	UNKNOWN
}

@export var id: String
@export var name: String = "Unnamed Effect"
@export var description: String = "Unnamed Effect"

@export var battle_only: bool = true
@export var single_trigger: bool = false
@export var priority: int = 200
@export var is_battle_only := false
@export var _should_append: bool = true

var owner: CharacterInstance = null
var source: ContextSource = null


func set_owner(_owner: CharacterInstance) -> void:
	owner = _owner

func set_source(_source: ContextSource) -> void:
	source = _source

@abstract
func listened_triggers() -> Array

@abstract
func can_process(_event: TriggerEvent) -> bool

func prepare_for_battle() -> void:
	pass

func should_append() -> bool:
	return _should_append

func on_trigger(_event: TriggerEvent) -> void:
	pass

func _get_name() -> String:
	return name

func get_description() -> String:
	return description

@abstract
func get_category() -> EffectCategory

func on_apply() -> void:
	pass

func on_expire() -> void:
	remove_self()

func remove_self() -> void:
	owner.remove_effect(self)

func _modifies_skill_cost() -> bool:
	return false

func modify_skill_cost(_skill: Skill) -> Skill:
	return _skill
