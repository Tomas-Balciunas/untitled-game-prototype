extends Node

signal character_damaged(c: Character, damage_instance: DamageInstance)
signal character_healed(c: Character, amt: int)
signal health_changed(c: Character, old: int, new: int)
signal stat_changed(c: Character, stat: Stats.StatRef)

## UI
signal display_character_menu(c: Character)
signal display_status_effects(c: Character)
signal skill_use_requested(skill: Skill)
