extends Label3D

func set_notification(notif: String, duration: float = 3.0) -> void:
	self.text = notif
	
	var tween = create_tween()
	tween.set_parallel()
	
	var rand_dir = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(0.7, 1.6),
		randf_range(-1.0, 1.0)
	).normalized() * 1.0
	
	tween.tween_property(self, "position", position + rand_dir, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	
	position += Vector3(randf_range(-0.3, 0.3), 0.0, randf_range(-0.3, 0.3))
	
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
