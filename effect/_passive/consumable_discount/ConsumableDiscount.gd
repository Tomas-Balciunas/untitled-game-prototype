extends PassiveEffect

class_name ConsumableDiscount


@export_range(0.0, 1.0) var buy_reduction: float = 0.2
@export_range(0.0, 1.0) var sell_bonus: float = 0.0


func get_scope() -> Effect.EffectScope:
	return Effect.EffectScope.GLOBAL


func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return false


func listened_triggers() -> Array:
	return []


func _modifies_shop_price() -> bool:
	return true


func modify_shop_price(item: Item, is_buy: bool, price: int) -> int:
	if not (item is Consumable):
		return price

	var ratio := (1.0 - buy_reduction) if is_buy else (1.0 + sell_bonus)
	return int(round(price * ratio))
