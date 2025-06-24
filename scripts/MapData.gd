extends Resource

class_name MapData

# Properties for the map configuration
@export var data: Array = []  # 2D array of dictionaries for tile data
@export var theme: String = ""  # Theme or style of the map
@export var start_pos: Vector2 = Vector2.ZERO  # Starting position
@export var transitions: Dictionary = {}  # Map transitions
