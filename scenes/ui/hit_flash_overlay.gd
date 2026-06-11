extends ColorRect

class_name HitFlashOverlay

const FLASH_COLOR := Color(0.85, 0.05, 0.05)
const MIN_ALPHA := 0.35
const MAX_ALPHA := 0.75
const CRIT_BONUS := 0.15
const ALPHA_CAP := 0.85
const FULL_FLASH_DAMAGE_RATIO := 0.5
const FADE_TIME := 0.35

const VIGNETTE_SHADER := "
shader_type canvas_item;

uniform float inner_radius = 0.35;
uniform float outer_radius = 0.75;

void fragment() {
	float dist = distance(UV, vec2(0.5));
	COLOR.a *= smoothstep(inner_radius, outer_radius, dist);
}
"

var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = FLASH_COLOR
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	material = mat

	CharacterBus.character_damaged.connect(_on_damaged)


func _on_damaged(c: Character, damage_instance: DamageInstance) -> void:
	if not PartyManager.has_member_by_object(c):
		return

	if not damage_instance.calculator or damage_instance.calculator.get_final_damage() <= 0:
		return

	_flash(_peak_alpha(c, damage_instance))


func _peak_alpha(c: Character, damage_instance: DamageInstance) -> float:
	var max_health := float(c.stats.health)
	var ratio := 0.0

	if max_health > 0:
		ratio = float(damage_instance.calculator.get_final_damage()) / max_health

	var alpha := lerpf(MIN_ALPHA, MAX_ALPHA, clampf(ratio / FULL_FLASH_DAMAGE_RATIO, 0.0, 1.0))

	if damage_instance.calculator.is_critical:
		alpha += CRIT_BONUS

	return minf(alpha, ALPHA_CAP)


func _flash(peak: float) -> void:
	if _tween:
		_tween.kill()

	modulate.a = maxf(peak, modulate.a)
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
