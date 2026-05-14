extends InteractionCondition

class_name HasEffectCondition


@export var effect_id: String = ""
@export var target_member_id: String = ""


func matches(_c: BaseCharacterResource) -> bool:
	if effect_id == "":
		push_error("HasEffectCondition has empty effect_id")
		return false

	if target_member_id != "":
		for m: Character in PartyManager.members:
			if m.resource.id == target_member_id:
				return _member_has(m)
		return false

	for m: Character in PartyManager.members:
		if _member_has(m):
			return true

	return false


func _member_has(m: Character) -> bool:
	for e: Effect in m.effects:
		if e.id == effect_id:
			return true
	return false


static func any_has(p_effect_id: String) -> HasEffectCondition:
	var c := HasEffectCondition.new()
	c.effect_id = p_effect_id
	return c


static func member_has(p_member_id: String, p_effect_id: String) -> HasEffectCondition:
	var c := HasEffectCondition.new()
	c.effect_id = p_effect_id
	c.target_member_id = p_member_id
	return c
