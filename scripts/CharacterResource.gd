extends Resource

class_name CharacterResource

enum Gender {MALE, FEMALE}

@export var gender: Gender
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
