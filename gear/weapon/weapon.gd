extends Gear

class_name Weapon

@export var targeting: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE

func instantiate() -> GearInstance:
	var inst := GearInstance.new(self)
	inst.template = self
	return inst
