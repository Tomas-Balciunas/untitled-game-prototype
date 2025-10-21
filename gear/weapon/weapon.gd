extends Gear

class_name Weapon

enum Type {
	SWORD,
	AXE
}

@export var targeting: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE
@export var weapon_type: Type = Type.SWORD 
@export var accuracy_range: int = 0

func instantiate() -> GearInstance:
	var inst := GearInstance.new(self)
	inst.template = self
	return inst
