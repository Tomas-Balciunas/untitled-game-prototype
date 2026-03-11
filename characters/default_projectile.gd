extends RigidBody3D

@onready var timer: Timer = $Timer

var event: ActionEvent = null
var velocity: Vector3
var lifetime: float = 1.0


func launch_projectile(_event: ActionEvent, direction: Vector3, speed: float, travel_time: float) -> void:
	event = _event
	velocity = direction * speed
	lifetime = travel_time

	linear_velocity = velocity
	timer.start(lifetime)


func _on_timer_timeout() -> void:
	if event:
		event.confirm()
	
	queue_free()
