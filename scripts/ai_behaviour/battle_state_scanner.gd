extends Node

class_name BattleStateScanner

var enemies: Array = []
var party: Array = []

func _init(_enemies: Array[Character], _party: Array[Character]) -> void:
	for enemy: Character in _enemies:
		enemies.append(scan_battler(enemy))
	
	for party_member in _party:
		party.append(scan_battler(party_member))

func scan_battler(battler: Character) -> Array:
	var data: Array = [null, null]
	data[0] = battler
	var tags: Array[String] = []
	
	var hp_percent = battler.state.current_health / battler.stats.health

	if hp_percent < 1.0:
		tags.append(StateTags.HEALTH_NOT_FULL)
		
		if hp_percent < 0.5:
			tags.append(StateTags.HEALTH_UNDER_50)
	else:
		tags.append(StateTags.HEALTH_FULL)
	
	for effect: Effect in battler.effects:
		tags.append_array(effect.get_tags())
	
	data[1] = tags
	
	return data
