extends Resource
class_name Effect
@export_category("Effect")

var owner: CharacterInstance = null

func on_apply(owner: CharacterInstance) -> void:
	self.owner = owner

func on_expire(owner: CharacterInstance) -> void:
	pass

func on_trigger(trigger: String, data) -> void:
	pass
