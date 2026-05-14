extends CharacterChatter

class_name LiliChatter


func _init() -> void:
	lines = {
		"damaged": {
			"default": ["owch", "ugh"],
			"special": {},
		},
		"attacking": {
			"default": ["Hiyah!", "Die!"],
			"special": {},
		},
	}
