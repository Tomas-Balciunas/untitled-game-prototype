extends Node

signal character_damaged(c: CharacterInstance, amt: int)
signal character_healed(c: CharacterInstance, amt: int)
signal health_changed(c: CharacterInstance, old: int, new: int)
signal stat_changed(c: CharacterInstance, stat: Stats.StatRef)

## UI
signal display_character_menu(c: CharacterInstance)
signal skill_use_requested(skill: Skill)
