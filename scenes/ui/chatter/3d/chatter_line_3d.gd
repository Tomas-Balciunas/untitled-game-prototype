extends Label3D

func chat(txt: String) -> void:
	text = ""
	for letter in txt:
		text += letter
		await get_tree().create_timer(0.09).timeout
		
	await get_tree().create_timer(0.8).timeout
	queue_free()
