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
	OWNER_IS_ACTOR,
	OWNER_IS_TARGET,
	GLOBAL
}

enum EffectType {
	BASIC_ATTACK
}

## Which point in a turn an effect's duration countdown / expiry is evaluated.
## CUSTOM means the effect manages its own removal (e.g. a random recovery
## roll) and is skipped by the automatic countdown and the turn display.
enum TurnPhase {
	TURN_START,
	TURN_END,
	CUSTOM,
	NONE
}

@export var id: String
@export var name: String = "Unnamed Effect"
@export var description: String = "Unnamed Effect"
@export var icon: Texture2D

@export var native: bool = false
@export var show_in_status: bool = true

## effective in battle only
@export var battle_only: bool = true

## ephemeral effects like stun which doesnt persist after battle ends
## if true, will be removed after battle
@export var expires_after_battle: bool = false

## triggered immediately and removed during the same state
@export var immediate_trigger: bool = false

@export var process_when_dead: bool = false
@export var priority: int = 200
@export var effect_type: Array[EffectType] = []

@export var duration_turns: int = -1

## if custom, should override and implement custom logic
@export var expire_phase: TurnPhase = TurnPhase.TURN_END

var remaining_turns: int = -1

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

func show_in_status_screen() -> bool:
	return show_in_status

func show_in_character_menu() -> bool:
	return native

func get_icon() -> Texture2D:
	return icon

func get_display_turns() -> int:
	if not is_turn_based() or [TurnPhase.CUSTOM, TurnPhase.NONE].has(expire_phase):
		return -1
	return remaining_turns

func get_display_stacks() -> int:
	return -1

@abstract
func get_category() -> EffectCategory

func is_turn_based() -> bool:
	return duration_turns >= 0

func on_turn_start() -> void:
	_tick_duration(TurnPhase.TURN_START)

func on_turn_end() -> void:
	_tick_duration(TurnPhase.TURN_END)

func _tick_duration(phase: TurnPhase) -> void:
	if not is_turn_based():
		return
	
	if phase != expire_phase:
		return
	
	consume_duration()

func consume_duration(amount: int = 1) -> void:
	if not is_turn_based():
		return
	remaining_turns -= amount
	if remaining_turns <= 0:
		on_expire()

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

func _modifies_shop_price() -> bool:
	return false

func modify_shop_price(_item: Item, _is_buy: bool, price: int) -> int:
	return price

func tick(_ctx: ActionContext) -> void:
	pass

func owner_is_target(event: TriggerEvent) -> bool:
	return owner == event.target

func owner_is_actor(event: TriggerEvent) -> bool:
	return owner == event.source.get_actor()

func can_process_when_dead() -> bool:
	return process_when_dead

func get_priority(_stage: String) -> int:
	return priority

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
