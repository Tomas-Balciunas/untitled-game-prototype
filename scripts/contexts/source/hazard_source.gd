extends ContextSource
class_name HazardSource

var hazard: Hazard

func _init(h: Hazard = null) -> void:
	hazard = h

func get_type() -> SourceType:
	return ContextSource.SourceType.HAZARD

func get_source_name() -> String:
	return hazard.name if hazard else "Hazard"

func get_damage_type() -> DamageTypes.Type:
	return hazard.damage_type if hazard else DamageTypes.Type.PHYSICAL

func game_save() -> Dictionary:
	var data := super.game_save()
	data["hazard_id"] = hazard.id if hazard else ""
	return data

static func from_save(data: Dictionary) -> HazardSource:
	var hazard_id: String = data.get("hazard_id", "")
	if hazard_id.is_empty() or not HazardRegistry.has_hazard(hazard_id):
		return null
	return HazardSource.new(HazardRegistry.get_hazard(hazard_id))
