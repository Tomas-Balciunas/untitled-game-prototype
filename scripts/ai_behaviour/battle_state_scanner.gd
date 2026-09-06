extends RefCounted

class_name BattleStateScanner

var enemies: Array = []
var allies: Array = []

func _init(_enemies: Array[Character], _party: Array[Character], actor_party_member: bool) -> void:
	for enemy: Character in _enemies:
		if actor_party_member == false:
			allies.append(scan_battler(enemy))
			continue
		
		enemies.append(scan_battler(enemy))
	
	for party_member in _party:
		if actor_party_member == false:
			enemies.append(scan_battler(party_member))
			continue
		
		allies.append(scan_battler(party_member))

func scan_battler(battler: Character) -> Array:
	var data: Array = [null, null]
	data[0] = battler
	var tags: Array[String] = []
	
	## expand conditions when needed
	
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
