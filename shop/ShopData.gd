extends Resource
class_name ShopData


@export var id: String = ""
@export var shop_name: String = "Shop"
@export var entries: Array[ShopEntry] = []
@export_range(0.0, 1.0) var sell_price_ratio: float = 0.5


func get_save_id() -> String:
	return id if not id.is_empty() else shop_name
