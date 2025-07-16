extends Resource

class_name Attributes

@export var str: int = 0
@export var iq: int = 0
@export var pie: int = 0
@export var vit: int = 0
@export var dex: int = 0
@export var spd: int = 0
@export var luk: int = 0

func add(other: Attributes) -> void:
	str += other.str
	iq += other.iq
	pie += other.pie
	vit += other.vit
	dex += other.dex
	spd += other.spd
	luk += other.luk
