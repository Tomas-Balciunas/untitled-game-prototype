extends Node

var traps := {}
var basic_traps: Array[Trap] = []

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var basic_res_paths: Array[String] = [
		"res://trap/_traps/PoisonTrap.tres",
		"res://trap/_traps/ManaDrainTrap.tres"
		
	]
	
	var res_paths: Array[String] = [
		
		
	]
	
	for path in res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_trap(res)
	
	for path in basic_res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_trap(res)
			basic_traps.append(res)

func register_trap(trap: Trap) -> void:
	if trap.id in traps:
		push_warning("Duplicate mod id: %s" % trap.id)
		
	traps[trap.id] = trap

func get_trap(id: String) -> Trap:
	if traps.has(id):
		return traps[id]
		
	push_error("Modifier not found by %s" % id)
	return null

func get_random_trap() -> Trap:
	return basic_traps[randi() % len(basic_traps)]
