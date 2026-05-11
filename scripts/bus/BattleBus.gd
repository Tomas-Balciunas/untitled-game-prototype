extends Node

const SKILL = "skill"
const ITEM = "item"
const ATTACK = "attack"
const DEFEND = "defend"
const FLEE = "flee"

signal queue_processed(queue: Array[Character])
signal action_selected(action: String, entity: Variant)

signal battle_start
signal battle_end
signal ally_turn_started(ally: Character)
signal turn_started(battler: Character, is_party_member: bool)
signal turn_ended
signal enemy_died(dead: Character)
signal attack_connected
