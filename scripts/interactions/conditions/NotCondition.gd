extends InteractionCondition

class_name NotCondition


@export var child: InteractionCondition


func matches(c: BaseCharacterResource) -> bool:
	if child == null:
		push_error("NotCondition has no child")
		return false

	return not child.matches(c)


static func of(inner: InteractionCondition) -> NotCondition:
	var c := NotCondition.new()
	c.child = inner
	return c
