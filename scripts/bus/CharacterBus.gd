extends Node

signal character_damaged(c: CharacterInstance, amt: int)
signal character_healed(c: CharacterInstance, amt: int)
signal health_changed(c: CharacterInstance, old: int, new: int)

signal chat(c: CharacterInstance, text: String)
