extends Node

signal open_chest_requested(chest: Chest)
signal chest_opener_chosen(c: Character)
signal chest_state_changed(chest: Chest)

signal open_door_requested(door: Door)
signal door_opener_chosen(c: Character)

## UI signals
signal display_chest_opener
signal display_chest_content(chest: Chest)

signal display_door_opener
