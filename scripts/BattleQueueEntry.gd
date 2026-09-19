extends RefCounted

class_name BattleQueueEntry

var resolver: EffectResolver = null
var context: ActionContext = null
var actor: Character = null
var animation_name: String = ""
var action_name: String = "n/a"

func _init(res: EffectResolver, ctx: ActionContext, _actor: Character) -> void:
	resolver = res
	context = ctx
	actor = _actor

func run_queue_entry() -> void:
	var orchestrator: ActionOrchestrator = ActionOrchestrator.new(actor, context, resolver)
	await orchestrator.execute_action(
		func (event: ActionEvent) -> void:
			event.confirm(),
		action_name
	)

func set_animation(ani_name: String) -> void:
	animation_name = ani_name
