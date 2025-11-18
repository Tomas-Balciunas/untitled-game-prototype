extends Node

const SKILL = "skill"
const ITEM = "item"
const ATTACK = "attack"
const DEFEND = "defend"
const FLEE = "flee"

signal target_selected(target: CharacterInstance)
signal queue_processed(queue: Array[CharacterInstance])
signal action_selected(action: String, entity: Variant)
