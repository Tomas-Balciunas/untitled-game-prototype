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

var owner: CharacterInstance = null

func on_apply(owner: CharacterInstance) -> void:
	self.owner = owner

func on_expire(owner: CharacterInstance) -> void:
	pass

func on_trigger(trigger: String, data: ActionContext) -> void:
	pass
