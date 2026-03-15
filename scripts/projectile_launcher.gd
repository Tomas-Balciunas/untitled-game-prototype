@abstract
extends Node

class_name ProjectileLauncher

var resolver: EffectResolver = null
var ctx: ActionContext = null
var initial_target: CharacterInstance = null
var is_ally: bool = false
var initial_target_slot: FormationSlot = null
var actor: CharacterInstance = null
var actor_slot: FormationSlot = null
