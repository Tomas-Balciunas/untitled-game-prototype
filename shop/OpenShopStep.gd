extends EventStep
class_name OpenShopStep


@export var shop: ShopData


func run(_manager: EventManager) -> void:
	if shop == null:
		push_warning("OpenShopStep: no shop set")
		return

	ShopBus.shop_open_requested.emit(shop)
	await ShopBus.shop_closed
