extends Node

func set_notification(notif: String, duration: float = 3.0) -> void:
	self.text = notif
	set_kill(duration)

func set_kill(duration: float) -> void:
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = duration
	timer.timeout.connect(kill, CONNECT_ONE_SHOT)
	add_child(timer)
	
func kill() -> void:
	self.queue_free()
