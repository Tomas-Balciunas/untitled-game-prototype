extends CharacterChatter

class_name SkeltalChatter


func _init() -> void:
	lines = {
		"damaged": {
			"default": ["*rattle*", "*krr*"],
			"special": {},
		},
		"attacking": {
			"default": ["*angry rattle*", "..."],
		},
	}
