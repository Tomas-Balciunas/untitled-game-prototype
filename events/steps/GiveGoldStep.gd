extends EventStep
class_name GiveGoldStep


@export var amount: int = 0
@export var notify: bool = true


func run(_manager: EventManager) -> void:
	if amount <= 0:
		push_warning("GiveGoldStep: non-positive amount")
		return

	GameState.add_gold(amount)
	if notify:
		NotificationBus.notification_requested.emit("Party gained %d gold" % amount)
