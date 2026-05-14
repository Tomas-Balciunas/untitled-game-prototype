extends InteractionCondition

class_name AnyOfCondition


@export var children: Array[InteractionCondition] = []


func matches(c: BaseCharacterResource) -> bool:
	for child: InteractionCondition in children:
		if child.matches(c):
			return true

	return false


static func of(list: Array[InteractionCondition]) -> AnyOfCondition:
	var c := AnyOfCondition.new()
	c.children = list
	return c
