extends CharacterBody3D

const SPEED = 3.0

@export var encounter_data: EncounterData
@export var enemy_scene: PackedScene
@onready var encounter_area: BattleTrigger = $EncounterArea
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

var visual: CharacterBody3D
var origin: Vector3
var rng := RandomNumberGenerator.new()

func _physics_process(_delta: float) -> void:
	var current_location := global_transform.origin
	var next_location := navigation_agent_3d.get_next_path_position()
	var new_velocity := (next_location - current_location).normalized() * SPEED
	
	velocity = new_velocity
	move_and_slide()

func _ready() -> void:
	assert(encounter_data)
	assert(enemy_scene)
	EncounterBus.encounter_ended.connect(_on_encounter_ended)
	
	MapInstance.add_encounter(encounter_data)
	
	if MapInstance.is_encounter_cleared(encounter_data.id):
		queue_free()
		return
	
	encounter_area.encounter = encounter_data
	visual = enemy_scene.instantiate()
	add_child(visual)
	
	origin = global_transform.origin
	
	
func update_target_location(target_location: Vector3) -> void:
	navigation_agent_3d.target_position = target_location

func _on_encounter_ended(_res: String, data: EncounterData) -> void:
	if data.id == encounter_data.id:
		self.queue_free()


func _on_detection_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	var player = get_tree().get_root().get_node("Main/Player")
	update_target_location(player.global_transform.origin)
