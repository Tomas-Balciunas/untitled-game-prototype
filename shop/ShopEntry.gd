extends Resource
class_name ShopEntry


@export var item: ItemResource
@export var price: int = 0
@export var stock: int = -1


func is_infinite() -> bool:
	return stock < 0
