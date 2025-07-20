extends Resource

class_name CharacterResource

const DEFAULT_RACE   = preload("res://characters/_race/_Unknown.tres")
const DEFAULT_JOB    = preload("res://characters/_class/_Unknown.tres")
const DEFAULT_GENDER = preload("res://characters/_gender/_Unknown.tres")
const DEFAULT_ATTRIBUTES = preload("res://characters/_attribute/_Unknown.tres")

@export var race: Race = DEFAULT_RACE
@export var job: Job = DEFAULT_JOB
@export var gender: Gender = DEFAULT_GENDER

@export var attributes: Attributes = DEFAULT_ATTRIBUTES

@export var id: int = 0

@export var character_body: PackedScene
@export var portrait: Texture
@export var name: String = "Unnamed"
@export var attack_power: int
@export var health_points: int = 20
@export var mana_points: int = 10
@export var defense: int = 10
@export var speed: int = 10
@export var experience: int = 0
@export var slot_width: int = 1
@export var prefers_front_row: bool = true
@export var default_skills: Array[Skill] = []
@export var default_effects: Array[Effect] = []
@export var default_damage_type: DamageTypes.Type
@export var default_weapon: Weapon
