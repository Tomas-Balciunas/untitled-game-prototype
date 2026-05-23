extends PanelContainer
class_name ShopRow


signal buy_pressed
signal sell_pressed


@onready var name_label: Label = %Name
@onready var price_label: Label = %Price
@onready var stock_label: Label = %Stock
@onready var action_button: Button = %Action


func bind_buy(entry: ShopEntry, price: int) -> void:
	name_label.text = entry.item.name if entry.item else "<missing>"
	price_label.text = "%d g" % price
	stock_label.text = "inf" if entry.is_infinite() else "x%d" % entry.stock
	action_button.text = "Buy"
	action_button.disabled = entry.stock == 0
	action_button.pressed.connect(buy_pressed.emit)


func bind_sell(item: Item, price: int) -> void:
	name_label.text = item.get_item_name()
	price_label.text = "%d g" % price
	stock_label.text = ""
	action_button.text = "Sell"
	action_button.pressed.connect(sell_pressed.emit)
