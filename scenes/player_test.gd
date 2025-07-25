extends Node3D

signal player_moved(data: Dictionary)
signal start_encounter(data: Dictionary)
signal map_transition(data: Dictionary)

const TRAVEL_TIME := 0.3

@onready var front_ray := $FrontRay
@onready var back_ray := $BackRay
@onready var left_ray := $LeftRay
@onready var right_ray := $RightRay

var can_move = true
var tween : Tween

func _ready():
	EncounterManager.connect("encounter_started", Callable(self, "_on_encounter_started"))
	EncounterManager.connect("encounter_ended", Callable(self, "_on_encounter_ended"))

func _physics_process(delta):
	if not can_move:
		return
	if tween is Tween:
		if tween.is_running():
			return
	if Input.is_action_pressed("move_forward") and not front_ray.is_colliding():
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.FORWARD * 2), TRAVEL_TIME)
	if Input.is_action_pressed("move_backwards") and not back_ray.is_colliding():
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.BACK * 2), TRAVEL_TIME)
	if Input.is_action_pressed("strafe_left") and not left_ray.is_colliding():
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.LEFT * 2), TRAVEL_TIME)
	if Input.is_action_pressed("strafe_right") and not right_ray.is_colliding():
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform", transform.translated_local(Vector3.RIGHT * 2), TRAVEL_TIME)
	if Input.is_action_pressed("turn_left"):
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, PI / 2), TRAVEL_TIME)
	if Input.is_action_pressed("turn_right"):
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, -PI / 2), TRAVEL_TIME)

func _on_encounter_started(encounter_data):
	can_move = false
	
func _on_encounter_ended(result):
	can_move = true
