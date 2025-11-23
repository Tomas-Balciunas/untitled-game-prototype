extends Node
class_name OverworldNPC

@export var character: BaseCharacterResource = null

@onready var overworld_npc_interactable: OverworldNPCInteractable = $OverworldNpcInteractable

var npc_name: String = "???"
var npc_body: PackedScene = null

func _ready() -> void:
	overworld_npc_interactable.overworld_npc_interact_request.connect(_on_interact_requested)
	
	if character:
		npc_name = character.name
		npc_body = character.character_body
		
	if not npc_body:
		push_error("NPC %s doesnt have a body!" % npc_name)
		return
		
	add_child(npc_body.instantiate())

func _should_spawn() -> bool:
	return true
	
func _get_body() -> PackedScene:
	if character:
		return character.character_body
	
	return npc_body
	
func _get_name() -> String:
	if character:
		return character.name
	
	return npc_name


func _on_interact_requested() -> void:
	if not character.interactions:
		push_error("interactions not found for %s" % character.name)
		
	if not character.interaction_controller:
		push_error("character interaction controller not found for %s" % character.name)
		
	character.interaction_controller.handle(character)
