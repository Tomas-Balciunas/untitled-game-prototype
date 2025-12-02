extends Node

signal open_chest_requested(chest: Chest)
signal chest_opener_chosen(c: CharacterInstance)
signal chest_state_changed(chest: Chest)

## UI signals
signal display_chest_opener
signal display_chest_content(chest: Chest)
