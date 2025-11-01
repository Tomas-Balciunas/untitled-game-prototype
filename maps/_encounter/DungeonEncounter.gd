extends Node3D

@export var encounter_data: EncounterData
@export var enemy_scene: PackedScene
@onready var encounter_area: BattleTrigger = $EncounterArea
@export var move_radius := 3.0
@export var step_time := 1.5
@export var idle_time_min := 0.5
@export var idle_time_max := 2.0

var visual: CharacterBody3D
var origin: Vector3
var rng := RandomNumberGenerator.new()

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
	#_start_patrol()
	
func _start_patrol() -> void:
	_patrol_step()

func _patrol_step() -> void:
	var dir := Vector3(rng.randf_range(-1,1), 0, rng.randf_range(-1,1))
	if dir.length() == 0:
		dir = Vector3(0,0,1)
	dir = dir.normalized()
	var dist := rng.randf_range(0.5, move_radius)
	var target := origin + dir * dist

	var t := create_tween()
	t.tween_property(self, "global_transform:origin", target, step_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	t.finished.connect(Callable(self, "_on_step_finished"))

func _on_step_finished() -> void:
	var idle := rng.randf_range(idle_time_min, idle_time_max)
	await get_tree().create_timer(idle).timeout
	_start_patrol()

func _on_encounter_ended(_res, data) -> void:
	if data.id == encounter_data.id:
		self.queue_free()
