extends Label

func set_notification(notif: String, duration: float = 3.0) -> void:
	self.text = notif
	
	var tween = create_tween()
	tween.set_parallel()
	
	var rand_dir = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-2.2, -0.8)
	).normalized() * 45
	
	tween.tween_property(self, "position", position + rand_dir, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	
	position += Vector2(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4))
	
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
