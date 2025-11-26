@abstract
extends Resource

class_name CharacterInteraction


## --- System ---
const ID = "id"
const TAG = "tag"
const PRIORITY = "priority"
const EVENT = "event"
const TYPE = "type"
const TEXT = "text"
const CHOICE = "choice"
const PERSISTENT = "persistent"
const CALLBACK = "callback"
const FUNC = "func"
const RANDOM = "random"
const RECURRING = "recurring"

## --- Events ---
const CHOICES = "choices"
const BTN_TEXT = "btn_text"

## -- Conditions --
const CONDITIONS = "conditions"
const STATE = "state"
const CONTAINS = "contains"
const TAGS = "tags"
const SELF = "self"
const CHARACTER = "character"
const AVAILABLE = InteractionTagManager.AVAILABLE
const COMPLETED = InteractionTagManager.COMPLETED

## -- On Completed --
const ON_COMPLETED = "on_completed"
const MARK_COMPLETED = "mark_completed"
const MARK_AVAILABLE = "mark_available"

## Content
const MENU_TALK = "menu_talk"
const BATTLE_EVENT = "battle_event"
const FIRST_ENCOUNTER = "first_encounter"


func _get_default_tags() -> Array:
	return []


@abstract
func get_chatter(_topic: String) -> String


@abstract
func get_interactions() -> Array


#func get_battle_event(_id: String) -> Array:
	#return []
#
#func get_damaged_line(_key: String, _amt: int, _ctx: DamageContext = null) -> String:
	#return ""
#
#func get_attacking_line(_key: String, _source: CharacterInstance, _targets: Array) -> String:
	#return ""
