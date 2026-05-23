extends Resource
class_name ShopData


@export var shop_name: String = "Shop"
@export var entries: Array[ShopEntry] = []
@export_range(0.0, 1.0) var sell_price_ratio: float = 0.5
