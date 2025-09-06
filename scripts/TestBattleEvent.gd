extends BattleEvent

class_name TestBattleEvent

var times = 1

func prepare(owner: CharacterInstance):
	BattleEventBus.before_receive_damage.connect(before_receive_damage)
	ConversationManager.dialogue_finished.connect(conclude_dialogue)
	_owner = owner
	_is_connected = true
	
func run():
	pass

func before_receive_damage(ctx: DamageContext):
	if ctx.target == _owner and ctx.final_value >= _owner.stats.current_health and times > 0:
		BattleFlow.pause()
		var interaction: CharacterInteraction = _owner.resource.interactions
		var lines = _owner.resource.interactions.get_dialogue(interaction.BATTLE_EVENT, interaction.FATAL_HIT)
		ConversationManager.show_dialogue(_owner.resource.name, lines["text"])
		ctx.final_value = 0
		times -= 1

func conclude_dialogue():
	BattleFlow.resume()
	if times <= 0:
		pass # add logic to remove event from character

func cleanup():
	if BattleEventBus.before_receive_damage.is_connected(Callable(self, "before_receive_damage")):
			BattleEventBus.before_receive_damage.disconnect(Callable(self, "before_receive_damage"))
	if ConversationManager.dialogue_finished.is_connected(Callable(self, "conclude_dialogue")):
		ConversationManager.dialogue_finished.disconnect(Callable(self, "conclude_dialogue"))
