extends RefCounted

class_name BattleStateScanner

var enemies: Array[BattleScanEntry] = []
var allies: Array[BattleScanEntry] = []

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

func scan_battler(battler: Character) -> BattleScanEntry:
	var entry: BattleScanEntry = BattleScanEntry.new(battler)
	
	## expand conditions later
	
	entry.tags.append(StateTags.DEAD if battler.is_dead else StateTags.ALIVE)

	var max_health: int = battler.stats.health
	var hp_percent: float = float(battler.state.current_health) / max_health if max_health > 0 else 0.0

	if hp_percent < 1.0:
		entry.tags.append(StateTags.HEALTH_NOT_FULL)
		
		if hp_percent < 0.5:
			entry.tags.append(StateTags.HEALTH_UNDER_50)
	else:
		entry.tags.append(StateTags.HEALTH_FULL)
	
	for effect: Effect in battler.effects:
		entry.tags.append_array(effect.get_tags())
	
	return entry
