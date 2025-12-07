extends RefCounted
class_name SignalFailsafe

static func await_signal_or_timeout(node: Node, sig: Signal, timeout_seconds: float) -> bool:
	var dummy_obj: RefCounted = RefCounted.new()
	dummy_obj.add_user_signal("result")
	
	var signal_first: Callable = func() -> void:
		dummy_obj.emit_signal("result", false)
	
	var timeout_first: Callable = func() -> void:
		dummy_obj.emit_signal("result", true)
	
	node.get_tree().create_timer(timeout_seconds).timeout.connect(timeout_first, CONNECT_ONE_SHOT)
	sig.connect(signal_first, CONNECT_ONE_SHOT)
	
	var dummy_signal := Signal(dummy_obj, "result")
	var result: bool = await dummy_signal

	return result
