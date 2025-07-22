extends Node

var battle_events: Dictionary = {
	"test_battle_event": {
		"trigger": BattleManager.BattleState.TURN_START,
		"condition": { "turn_number": 3 },
		"actions": [
			{ "type": "show_text", "speaker": "Ally", "lines": ["We can do this!"] },
			{ "type": "pause_turns", "duration": 2 },
			{ "type": "spawn_ally", "character_id": 55, "slot": 2 },
		]
	},
}
