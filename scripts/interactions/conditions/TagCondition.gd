extends InteractionCondition

class_name TagCondition


enum Target { SELF, OTHER, ANY_PARTY_MEMBER }
enum State { AVAILABLE, COMPLETED }


@export var target: Target = Target.SELF
@export var target_id: String = ""
@export var state: State = State.AVAILABLE
@export var tag: String = ""
@export var must_contain: bool = true


func matches(c: BaseCharacterResource) -> bool:
	var ids := _resolve_ids(c)

	if ids.is_empty():
		return not must_contain

	for id: String in ids:
		var has := _has_state_for(id)

		if must_contain and not has:
			return false
		if not must_contain and has:
			return false

	return true


func _resolve_ids(c: BaseCharacterResource) -> Array[String]:
	var ids: Array[String] = []

	match target:
		Target.SELF:
			ids.append(c.id)
		Target.OTHER:
			if target_id == "":
				push_error("TagCondition.OTHER missing target_id")
			else:
				ids.append(target_id)
		Target.ANY_PARTY_MEMBER:
			for m: Character in PartyManager.members:
				ids.append(m.resource.id)

	return ids


func _has_state_for(id: String) -> bool:
	match state:
		State.AVAILABLE:
			return InteractionTagManager._has_available_tag_for(id, tag)
		State.COMPLETED:
			return InteractionTagManager._has_completed_tag_for(id, tag)

	return false


static func self_available(t: String) -> TagCondition:
	var c := TagCondition.new()
	c.tag = t
	c.state = State.AVAILABLE
	c.must_contain = true
	return c


static func self_completed(t: String) -> TagCondition:
	var c := TagCondition.new()
	c.tag = t
	c.state = State.COMPLETED
	c.must_contain = true
	return c


static func self_not_completed(t: String) -> TagCondition:
	var c := TagCondition.new()
	c.tag = t
	c.state = State.COMPLETED
	c.must_contain = false
	return c


static func other_completed(other_id: String, t: String) -> TagCondition:
	var c := TagCondition.new()
	c.target = Target.OTHER
	c.target_id = other_id
	c.tag = t
	c.state = State.COMPLETED
	c.must_contain = true
	return c


static func party_member_completed(t: String) -> TagCondition:
	var c := TagCondition.new()
	c.target = Target.ANY_PARTY_MEMBER
	c.tag = t
	c.state = State.COMPLETED
	c.must_contain = true
	return c
