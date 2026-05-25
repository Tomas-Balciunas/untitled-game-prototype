extends Resource

class_name EncounterData

@export var id: String
@export var description: String
@export var enemies: Array[CharacterResource]
@export var arena: String = "arena_default_00"
@export var experience_reward: int
@export var gold_reward: int = 0
@export var item_rewards: Array[ItemResource] = []
@export var reward_event: EventResource
@export var level_range: Array = []
