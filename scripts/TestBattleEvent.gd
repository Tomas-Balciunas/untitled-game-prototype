extends BattleEvent

class_name TestBattleEvent

var times = 1

func prepare(owner: Character):
	BattleEventBus.before_receive_damage.connect(before_receive_damage)
	ConversationBus.conversation_finished.connect(conclude_conversation)
	_owner = owner
	_is_connected = true
	
func run():
	pass

func before_receive_damage(ctx: DamageContext):
	if ctx.target == _owner and ctx.final_value >= _owner.stats.current_health and times > 0:
		push_warning("TestBattleEvent fatal-hit dialogue path is not wired to the new interaction system")
		ctx.final_value = 0
		times -= 1

func conclude_conversation():
	BattleFlow.resume()
	if times <= 0:
		pass # add logic to remove event from character

func cleanup():
	if BattleEventBus.before_receive_damage.is_connected(Callable(self, "before_receive_damage")):
			BattleEventBus.before_receive_damage.disconnect(Callable(self, "before_receive_damage"))
	if ConversationBus.conversation_finished.is_connected(Callable(self, "conclude_conversation")):
		ConversationBus.conversation_finished.disconnect(Callable(self, "conclude_conversation"))
