@abstract
extends Node

class_name ProjectileLauncher

var resolver: EffectResolver = null
var ctx: ActionContext = null
var initial_target: Character = null
var is_ally: bool = false
var initial_target_slot: FormationSlot = null
var actor: Character = null
var actor_slot: FormationSlot = null
