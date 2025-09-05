extends Node

signal resumed

var _paused: bool = false


func pause() -> void:
	if not _paused:
		_paused = true

func resume() -> void:
	if _paused:
		_paused = false
		resumed.emit()

func is_paused() -> bool:
	return _paused

func wait_if_paused() -> void:
	if _paused:
		await resumed
