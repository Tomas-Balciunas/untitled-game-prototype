extends CharacterBody3D

enum TargetType { PATROL, PLAYER }

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var player: CharacterBody3D = get_tree().get_root().get_node("Main/Player")
@onready var chase_timer: Timer = $ChaseTimer
@onready var idle_timer: Timer = $IdleTimer

@export var encounter_data: EncounterData
@export var enemy_scene: PackedScene
@export var speed := 1.2
@export var chase_duration := 2
@export var idle_duration := 2

var visual: CharacterBody3D
var origin: Vector3

var current_target_type := TargetType.PATROL
var player_detected: bool = false
var can_move := true


func _physics_process(_delta: float) -> void:
	if player_detected and current_target_type == TargetType.PLAYER:
		update_target_location(player.global_transform.origin)
	
	var current_location := global_transform.origin
	var next_location := navigation_agent_3d.get_next_path_position()
	var new_velocity := (next_location - current_location).normalized() * speed
	
	velocity = new_velocity
	
	if can_move:
		move_and_slide()

func _ready() -> void:
	assert(encounter_data)
	assert(enemy_scene)
	EncounterBus.encounter_ended.connect(_on_encounter_ended)
	navigation_agent_3d.target_reached.connect(_on_target_reached)
	
	MapInstance.add_encounter(encounter_data)
	
	if MapInstance.is_encounter_cleared(encounter_data.id):
		queue_free()
		return
	
	visual = enemy_scene.instantiate()
	add_child(visual)
	
	origin = global_transform.origin
	
	
func update_target_location(target_location: Vector3) -> void:
	navigation_agent_3d.target_position = target_location


func _on_encounter_ended(_res: String, data: EncounterData) -> void:
	if data.id == encounter_data.id:
		if MapInstance.is_encounter_cleared(data.id):
			self.queue_free()
		else:
			if player_detected:
				can_move = false
				idle_timer.start(idle_duration)


func _on_detection_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	
	chase_timer.stop()
	player_detected = true
	current_target_type = TargetType.PLAYER


func _on_detection_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	
	chase_timer.start(chase_duration)


func _on_target_reached() -> void:
	if not player_detected:
		return
		
	if not current_target_type == TargetType.PLAYER:
		return
	
	if player and global_position.distance_to(player.global_position) > 1.0:
		return
		
	EncounterBus.encounter_started.emit(encounter_data)


func _on_chase_timer_timeout() -> void:
	chase_timer.stop()
	player_detected = false
	current_target_type = TargetType.PATROL
	update_target_location(origin)


func _on_idle_timer_timeout() -> void:
	can_move = true
