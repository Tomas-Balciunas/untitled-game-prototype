extends CharacterBody3D
class_name CharacterBody

signal hit_confirmed

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var sprite: Sprite3D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var number_display: FormationSlotNumbers = $NumberDisplay
@onready var projectile_spawn: Node3D
@export var health_bar: HealthBar

var body_owner: Character = null
var death_shader = preload("uid://crlilwavkuu5u")
var blood_particle_material = null

func _ready() -> void:
	play_idle()
	
	CharacterBus.character_damaged.connect(_on_damaged)
	CharacterBus.character_healed.connect(_on_healed)
	CharacterBus.health_changed.connect(on_health_changed)
	ChatEventBus.chat.connect(_on_chat)
	
	if body_owner and has_node("Healthbar"):
		var health_bar = get_node("Healthbar") as HealthBar
		health_bar.set_max_value(body_owner.stats.health)
		health_bar.set_value(body_owner.state.current_health)
	
	if body_owner and has_node("Name"):
		var level_and_name: Label3D = get_node("Name")
		level_and_name.text = "Lvl. %s %s" % [body_owner.level, body_owner.resource.name]


func _on_damaged(c: Character, damage_instance: DamageInstance) -> void:
	if body_owner and c == body_owner:
		animation_player.stop()
		play_damaged()
		number_display.display_damage(damage_instance)
	
func _on_healed(c: Character, amt: int) -> void:
	if body_owner and c == body_owner:
		number_display.display_heal(amt)

func on_health_changed(c: Character, old: int, new: int) -> void:
	if body_owner and has_node("Healthbar"):
		var health_bar = get_node("Healthbar") as HealthBar
		health_bar.set_max_value(body_owner.stats.health)
		health_bar.set_value(body_owner.state.current_health)

func _on_chat(c: Character, text: String) -> void:
	if c == body_owner and has_node("SmallChatter"):
		get_node("SmallChatter").chatter(text)

func play_idle() -> void:
	if animation_player.has_animation("idle"):
		animation_player.play("idle")

func play_dead() -> void:
	collision.disabled = true
	animation_player.pause()
	
	var h: int = sprite.hframes
	var v: int = sprite.vframes
	var frame: int = sprite.frame
	var col: int = frame % h
	var row: int = frame / h
	var uv_scale := Vector2(1.0 / float(h), 1.0 / float(v))
	var uv_offset := Vector2(float(col) / float(h), float(row) / float(v))
	
	var material := ShaderMaterial.new()
	material.shader = death_shader
	material.set_shader_parameter("albedo_texture", sprite.texture)
	material.set_shader_parameter("noise_strength", 0.12)
	material.set_shader_parameter("noise_scale", 25.0)
	material.set_shader_parameter("edge_color", Color(0.5, 0.0, 0.0, 1.0))
	material.set_shader_parameter("edge_size", 0.08)
	sprite.material_override = material
	
	material.set_shader_parameter("uv_scale", uv_scale)
	material.set_shader_parameter("uv_offset", uv_offset)
	
	var tween := create_tween()
	tween.tween_method(
		func(v): material.set_shader_parameter("death_progress", v),
		0.0,
		1.0,
		1
	)
	
	var particles = GPUParticles3D.new()
	particles.amount = 120
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.explosiveness = 0.7
	particles.emitting = true
	particles.process_material = ParticleProcessMaterial.new() if blood_particle_material == null else blood_particle_material
	
	if blood_particle_material == null:
		var process_mat = particles.process_material as ParticleProcessMaterial
		process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		process_mat.emission_box_extents = Vector3(0.2, 0.5, 0.2)
		process_mat.direction = Vector3(0, -1, 0)
		process_mat.spread = 60.0
		process_mat.initial_velocity_min = 0.0
		process_mat.initial_velocity_max = 4.0
		process_mat.gravity = Vector3(0, -11.8, 0)
		process_mat.scale_min = 0.05
		process_mat.scale_max = 0.12
		process_mat.color = Color(0.8, 0.0, 0.0, 1.0)
		process_mat.particle_flag_align_y = true
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(0.8, 0.0, 0.0, 1.0))
		gradient.add_point(1.0, Color(0.8, 0.0, 0.0, 0.0))
		
		var gradient_texture = GradientTexture1D.new()
		gradient_texture.gradient = gradient
		
		process_mat.color_ramp = gradient_texture
		
		particles.draw_pass_1 = PlaneMesh.new()
		particles.draw_pass_1.size = Vector2(0.08, 0.08)
	particles.draw_pass_1.size = Vector2(0.1, 0.3)
	add_child(particles)
	particles.position = sprite.position
	
	tween.tween_callback(func():
		particles.queue_free()
		visible = false
	)

func play_run() -> void:
	if animation_player.has_animation("run_front"):
		animation_player.play("run_front")

func play_run_back() -> void:
	if animation_player.has_animation("run_back"):
		animation_player.play("run_back")

func play_attack(event: ActionEvent, target_pos: Vector3) -> void:
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
		await hit_confirmed
		event.confirm()
		await animation_player.animation_finished
		
		return
	
	event.confirm()


func play_skill(event: ActionEvent, animation: String, target_pos: Vector3) -> void:
	if animation_player.has_animation(animation):
		animation_player.play(animation)
		await hit_confirmed
		event.confirm()
		await animation_player.animation_finished
		
		return
	
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
		await hit_confirmed
		event.confirm()
		await animation_player.animation_finished
	
	event.confirm()


func play_item_use(event: ActionEvent) -> void:
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
		await animation_player.animation_finished
	event.confirm()

func play_damaged() -> void:
	if animation_player.has_animation("damaged"):
		animation_player.play("damaged")
		await animation_player.animation_finished
	

func _on_anim_finish() -> void:
	if animation_player.has_animation("idle"):
		animation_player.play("idle")

func _attack_connected() -> void:
	hit_confirmed.emit()

func play_poison(event: ActionEvent) -> void:
	if has_node("StatusEffectAnimations"):
		var player: StatusEffectAnimation = get_node("StatusEffectAnimations")
		player.play_poison()
		event.confirm()
		
		return
		
	event.confirm()
		
