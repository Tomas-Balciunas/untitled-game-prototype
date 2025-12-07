extends CharacterBody3D
class_name CharacterBody

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var sprite: Sprite3D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var number_display: FormationSlotNumbers = $NumberDisplay

var body_owner: CharacterInstance = null


func _ready() -> void:
	play_idle()
	CharacterBus.character_damaged.connect(_on_damaged)
	CharacterBus.character_healed.connect(_on_healed)
	ChatEventBus.chat.connect(_on_chat)
	
func _on_damaged(c: CharacterInstance, amt: int) -> void:
	if body_owner and c == body_owner:
		play_damaged()
		number_display.display_damage(amt)
	
func _on_healed(c: CharacterInstance, amt: int) -> void:
	if body_owner and c == body_owner:
		number_display.display_heal(amt)
		
func _on_chat(c: CharacterInstance, text: String) -> void:
	if c == body_owner and has_node("SmallChatter"):
		get_node("SmallChatter").chatter(text)

func play_idle() -> void:
	if animation_player.has_animation("idle"):
		animation_player.play("idle")

func play_dead() -> void:
	if animation_player.has_animation("dead"):
		animation_player.play("dead")

func play_run() -> void:
	if animation_player.has_animation("run_front"):
		animation_player.play("run_front")

func play_run_back() -> void:
	if animation_player.has_animation("run_back"):
		animation_player.play("run_back")

func play_attack() -> void:
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
		await animation_player.animation_finished

func play_damaged() -> void:
	if animation_player.has_animation("damaged"):
		animation_player.play("damaged")
		await animation_player.animation_finished
	

func _on_anim_finish() -> void:
	if animation_player.has_animation("idle"):
		animation_player.play("idle")

func _attack_connected() -> void:
	BattleBus.attack_connected.emit()
