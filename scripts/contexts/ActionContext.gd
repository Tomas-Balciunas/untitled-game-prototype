extends Resource

class_name ActionContext

var source: CharacterInstance
var target: CharacterInstance
var tags: Array[Effect] = []
var options: Dictionary = {}
var actively_cast: bool = false
var skip_turn: bool = false
