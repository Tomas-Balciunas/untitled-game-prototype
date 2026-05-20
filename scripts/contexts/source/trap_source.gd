extends ContextSource
class_name TrapSource


func _init(t: Trap) -> void:
	trap = t
	
func get_type() -> SourceType:
	return ContextSource.SourceType.TRAP

func get_source_name() -> String:
	return trap.name


func game_save() -> Dictionary:
	var data := super.game_save()
	data["trap_id"] = trap.id if trap else ""
	return data


static func from_save(data: Dictionary) -> TrapSource:
	var trap_id: String = data.get("trap_id", "")
	if trap_id.is_empty():
		return null
	var trap_inst := TrapRegistry.get_trap(trap_id)
	if trap_inst == null:
		return null
	return TrapSource.new(trap_inst)
