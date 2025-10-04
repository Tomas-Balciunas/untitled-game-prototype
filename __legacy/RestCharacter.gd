extends Node

@onready var sprite: Sprite3D = $Sprite3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var interactable: CharacterInteractable = $Interactable

func set_character(char: CharacterInstance):
	if !char.resource.character_body:
		push_error("Rest character creation error: character %s has no body" % char.resource.name)
	
	var body_scene = char.resource.character_body.instantiate()
	self.add_child(body_scene)
	
	if body_scene.sprite :
		sprite = body_scene.sprite
	
	if body_scene.animation_player:
		anim_player = body_scene.animation_player
	
	interactable.set_character(char)
	body_scene.queue_free()
	
	if anim_player.has_animation("idle"):
		anim_player.current_animation = "idle"
