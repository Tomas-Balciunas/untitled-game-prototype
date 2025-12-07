extends Node

const SKILL = "skill"
const ITEM = "item"
const ATTACK = "attack"
const DEFEND = "defend"
const FLEE = "flee"

signal target_selected(target: CharacterInstance)
signal queue_processed(queue: Array[CharacterInstance])
signal action_selected(action: String, entity: Variant)

signal battle_start
signal battle_end
signal ally_turn_started(ally: CharacterInstance)
signal turn_started(battler: CharacterInstance, is_party_member: bool)
signal turn_ended
signal enemy_died(dead: CharacterInstance)
signal attack_connected
