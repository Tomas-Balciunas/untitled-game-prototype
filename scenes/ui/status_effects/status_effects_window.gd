extends Panel

class_name StatusEffectsWindow

@onready var title_label: Label = $Margin/Layout/Header/Title
@onready var effects_container: VBoxContainer = $Margin/Layout/Scroll/Effects
@onready var empty_label: Label = $Margin/Layout/Scroll/Effects/Empty


func _ready() -> void:
	CharacterBus.display_status_effects.connect(_on_display_requested)
	hide()


func _on_display_requested(character: Character) -> void:
	_populate(character)
	show()


func _populate(character: Character) -> void:
	_clear()

	title_label.text = character.resource.name

	var shown := 0
	for effect: Effect in character.effects:
		if not effect.show_in_status_screen():
			continue
		_add_row(effect)
		shown += 1

	empty_label.visible = shown == 0


func _clear() -> void:
	for child in effects_container.get_children():
		if child == empty_label:
			continue
		child.queue_free()


func _add_row(effect: Effect) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = effect.get_icon()
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = effect._get_name()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var turns := effect.get_display_turns()
	if turns >= 0:
		var turns_label := Label.new()
		turns_label.text = "%d turns" % turns
		row.add_child(turns_label)

	var stacks := effect.get_display_stacks()
	if stacks >= 0:
		var stacks_label := Label.new()
		stacks_label.text = "x%d" % stacks
		row.add_child(stacks_label)

	effects_container.add_child(row)


func _on_close_pressed() -> void:
	hide()
