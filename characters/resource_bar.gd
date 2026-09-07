extends Node3D

class_name ResourceBar

@export var stat: Stats.StatRef = Stats.StatRef.HEALTH
@export var fill_color: Color = Color(0.12223608, 0.7231175, 0.14469254)
@export var background_color: Color = Color(0.8542789, 0.002545419, 0.09364753)
@export var bar_size: Vector2i = Vector2i(100, 10)

@onready var viewport: SubViewport = $Viewport
@onready var progress_bar: ProgressBar = $Viewport/ProgressBar

func _ready() -> void:
	viewport.size = bar_size

	var fill := progress_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	fill.bg_color = fill_color
	progress_bar.add_theme_stylebox_override("fill", fill)

	var background := progress_bar.get_theme_stylebox("background").duplicate() as StyleBoxFlat
	background.bg_color = background_color
	progress_bar.add_theme_stylebox_override("background", background)

	if GameState.current_state == GameState.States.IN_BATTLE:
		visible = true

func refresh(c: Character) -> void:
	match stat:
		Stats.StatRef.HEALTH:
			progress_bar.max_value = c.stats.health
			progress_bar.value = c.state.current_health
		Stats.StatRef.MANA:
			progress_bar.max_value = c.stats.mana
			progress_bar.value = c.state.current_mana
		Stats.StatRef.SP:
			progress_bar.max_value = c.stats.sp
			progress_bar.value = c.state.current_sp
