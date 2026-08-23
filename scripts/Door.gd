extends Resource
class_name Door

@export var id: String = ""
@export var key: QuestItemResource = null
@export var trap: Trap = null
@export var is_open: bool = false
@export var was_locked: bool = false

var key_id: String = ""
var key_name: String = ""
var seal_name: String = ""
