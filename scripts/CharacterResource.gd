extends Resource

class_name CharacterResource

@export var gender: Gender
@export var race: Race
@export var job: Job
@export var id: int = 0

@export var character_body: PackedScene
@export var portrait: Texture
@export var name: String = "Unnamed"
@export var attack_power: int
@export var health_points: int = 20
@export var mana_points: int = 10
@export var speed: int = 10
@export var experience: int = 0
@export var slot_width: int = 1
@export var prefers_front_row: bool = true
@export var default_skills: Array[Skill] = []
@export var default_effects: Array[Effect] = []
@export var default_damage_type: DamageTypes.Type
