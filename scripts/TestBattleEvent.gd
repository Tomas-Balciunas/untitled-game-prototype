extends BattleEvent

class_name TestBattleEvent

var times = 1

func prepare(owner: CharacterInstance):
	BattleEventBus.before_receive_damage.connect(before_receive_damage)
	_owner = owner
	_is_connected = true
	
func run():
	pass

func before_receive_damage(ctx: DamageContext):
	if ctx.target == _owner and ctx.final_value >= _owner.stats.current_health and times > 0:
		var og_state = BattleContext.manager.current_state
		var interaction: TestInteractions = _owner.resource.interactions
		var lines = _owner.resource.interactions.get_dialogue(interaction.BATTLE_EVENT, interaction.FATAL_HIT)
		#BattleContext.manager.current_state = BattleContext.manager.BattleState.ANIMATING
		ConversationManager.show_dialogue(_owner.resource.name, lines["text"])
		#BattleContext.manager.current_state = og_state
		ctx.final_value = 0
		times -= 1
