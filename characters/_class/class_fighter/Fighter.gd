extends Job

class_name FighterClass

func _init() -> void:
	level_skills = {
		2: [preload("uid://cneghh04ud4gg"), preload("uid://drqy6f6xdgohu")],
		5: [preload("uid://d2u72es2eig6a")],
	}

	level_effects = {
		4: [preload("uid://h7vic11h4pe6")],
	}
