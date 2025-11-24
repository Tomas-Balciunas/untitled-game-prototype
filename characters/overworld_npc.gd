extends Node
class_name OverworldNPC

@export var character: BaseCharacterResource = null

@onready var overworld_npc_interactable: OverworldNPCInteractable = $OverworldNpcInteractable

var npc_name: String = "???"
var npc_body: PackedScene = null

func _ready() -> void:
	overworld_npc_interactable.overworld_npc_interact_request.connect(_on_interact_requested)
	PartyBus.party_member_added.connect(_on_party_member_added)
	
	if character:
		if PartyManager.has_member(character.id):
			queue_free()
			return
		
		npc_name = character.name
		npc_body = character.character_body
		character._setup_character()
		
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
		return
		
	if not character.interaction_controller:
		push_error("character interaction controller not found for %s" % character.name)
		return
		
	character.interaction_controller.handle(character)

func _on_party_member_added(member: CharacterInstance, _row: int, _slot: int) -> void:
	if character:
		if character.id == member.resource.id:
			queue_free()
