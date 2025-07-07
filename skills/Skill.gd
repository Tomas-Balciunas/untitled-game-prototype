extends Resource

class_name Skill
@export var name: String
@export var description: String
#@export var icon: Texture2D
@export var mp_cost: int = 0
@export var sp_cost: int = 0
@export var damage: int = 0


#func execute(user: CharacterInstance, targets: Array):
	#var runner = effect_scene.instantiate()
	#runner.setup(user, targets)
	#runner.run()
