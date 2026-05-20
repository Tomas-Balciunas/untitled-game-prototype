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

enum EffectScope {
	OWNER_IS_ACTOR,   # owner is the source of the triggering event
	OWNER_IS_TARGET,  # owner is being targeted (checks event.target then ctx.targets)
	GLOBAL            # fires for all events of this stage; scope handled in can_process
}

enum EffectType {
	BASIC_ATTACK
}

@export var id: String
@export var name: String = "Unnamed Effect"
@export var description: String = "Unnamed Effect"

@export var battle_only: bool = true
@export var expires_after_battle: bool = false
@export var immediate_trigger: bool = false
@export var process_when_dead: bool = false
@export var priority: int = 200
@export var effect_type: Array[EffectType] = []

var owner: Character = null
var source: ContextSource = null


func set_owner(_owner: Character) -> void:
	owner = _owner

func set_source(_source: ContextSource) -> void:
	source = _source

@abstract
func listened_triggers() -> Array

@abstract
func can_process(_stage: String, _event: TriggerEvent) -> bool

func get_scope() -> EffectScope:
	return EffectScope.GLOBAL

func prepare_for_battle() -> void:
	pass

func on_trigger(_stage: String, _ctx: TriggerEvent) -> void:
	pass

func _get_name() -> String:
	return name

func get_description() -> String:
	return description

@abstract
func get_category() -> EffectCategory

func on_apply() -> void:
	pass

func on_battle_end() -> void:
	pass

func on_expire() -> void:
	remove_self()

func remove_self() -> void:
	owner.remove_effect(self)

func _modifies_skill_cost() -> bool:
	return false

func modify_skill_cost(_skill: Skill, _sc: SkillCost) -> SkillCost:
	return _sc

func tick(_ctx: ActionContext) -> void:
	pass

func owner_is_target(event: TriggerEvent) -> bool:
	return owner == event.target

func owner_is_actor(event: TriggerEvent) -> bool:
	return owner == event.source.get_actor()

func can_process_when_dead() -> bool:
	return process_when_dead


func game_save() -> Dictionary:
	var script_path: String = ""
	var script: Script = get_script()
	if script:
		script_path = script.resource_path

	var props: Dictionary = {}
	for prop in get_property_list():
		var usage: int = prop.usage
		if usage & PROPERTY_USAGE_STORAGE and usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var prop_name: String = prop.name
			props[prop_name] = get(prop_name)

	var data := {
		"script": script_path,
		"props": props,
	}
	if source:
		data["source"] = source.game_save()
	return data


func game_load(data: Dictionary) -> void:
	var props: Dictionary = data.get("props", {})
	for prop_name: String in props.keys():
		set(prop_name, props[prop_name])

	if data.has("source"):
		var restored := ContextSource.create_from_save(data["source"])
		if restored:
			source = restored


static func create_from_save(data: Dictionary) -> Effect:
	var script_path: String = data.get("script", "")
	if script_path.is_empty():
		push_error("Effect.create_from_save: missing script path")
		return null
	var script: Script = load(script_path)
	if script == null:
		push_error("Effect.create_from_save: failed to load script '%s'" % script_path)
		return null
	return script.new()
