extends Area3D

@export var map_data: MapData = null

func _ready() -> void:
	self.connect("body_entered", Callable(self, "_on_player_entered_area"))

func _on_player_entered_area(body: CharacterBody3D) -> void:
	if body.is_in_group("player"):
		if not map_data:
			push_error("Starting transition error: no transition data found!")
		
		TransitionManager.transit_to_map_start(map_data.id)
