extends Resource

class_name Job

enum Name {
	FIGHTER,
	KNIGHT,
	MAGE,
	PRIEST,
	THIEF
}

@export var name: Name
@export var attributes: Attributes
@export var skills: Array[Skill]
@export var effects: Array[Effect]
