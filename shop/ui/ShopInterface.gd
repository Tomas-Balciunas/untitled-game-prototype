extends CanvasLayer
class_name ShopUIInterface


enum Tab { BUY, SELL }


const ROW_SCENE: PackedScene = preload("res://shop/ui/ShopRow.tscn")


@onready var panel: Control = $Panel
@onready var title_label: Label = %Title
@onready var gold_label: Label = %Gold
@onready var buy_tab_button: Button = %BuyTabButton
@onready var sell_tab_button: Button = %SellTabButton
@onready var item_list: VBoxContainer = %ItemList
@onready var close_button: Button = %CloseButton


var _shop: ShopData = null
var _tab: Tab = Tab.BUY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	panel.visible = false

	ShopBus.shop_open_requested.connect(open)
	close_button.pressed.connect(_close)
	buy_tab_button.pressed.connect(_set_tab.bind(Tab.BUY))
	sell_tab_button.pressed.connect(_set_tab.bind(Tab.SELL))
	CurrencyBus.gold_changed.connect(_refresh_gold)


func open(shop: ShopData) -> void:
	_shop = shop
	_tab = Tab.BUY
	title_label.text = shop.shop_name
	panel.visible = true
	_refresh_gold(GameState.gold)
	_rebuild()


func _close() -> void:
	panel.visible = false
	_shop = null
	ShopBus.shop_closed.emit()


func _set_tab(t: Tab) -> void:
	_tab = t
	_rebuild()


func _refresh_gold(g: int) -> void:
	gold_label.text = "Gold: %d" % g


func _rebuild() -> void:
	for c in item_list.get_children():
		c.queue_free()

	if _shop == null:
		return

	if _tab == Tab.BUY:
		_build_buy()
	else:
		_build_sell()


func _build_buy() -> void:
	for entry: ShopEntry in _shop.entries:
		if entry == null or entry.item == null:
			continue
		var price := _buy_price_for(entry)
		var row: ShopRow = ROW_SCENE.instantiate()
		item_list.add_child(row)
		row.bind_buy(entry, price)
		row.buy_pressed.connect(_on_buy.bind(entry, price))


func _build_sell() -> void:
	var leader := _get_leader()
	if leader == null:
		return
	for item: Item in leader.inventory.get_all_items():
		var price := _sell_price_for(item)
		var row: ShopRow = ROW_SCENE.instantiate()
		item_list.add_child(row)
		row.bind_sell(item, price)
		row.sell_pressed.connect(_on_sell.bind(item, price))


func _buy_price_for(entry: ShopEntry) -> int:
	var base := entry.price if entry.price > 0 else entry.item.value
	if not _has_price_modifiers():
		return base
	var preview: Item = entry.item._build_instance()
	if preview == null:
		return base
	return _apply_price_modifiers(preview, base, true)


func _sell_price_for(item: Item) -> int:
	var base := int(round(item.value * _shop.sell_price_ratio))
	return _apply_price_modifiers(item, base, false)


func _has_price_modifiers() -> bool:
	for member: Character in PartyManager.members:
		for e: Effect in member.effects:
			if e._modifies_shop_price():
				return true
	return false


func _apply_price_modifiers(item: Item, base: int, is_buy: bool) -> int:
	var p := base
	for member: Character in PartyManager.members:
		for e: Effect in member.effects:
			if e._modifies_shop_price():
				p = e.modify_shop_price(item, is_buy, p)
	return max(0, p)


func _get_leader() -> Character:
	if PartyManager.members.is_empty():
		return null
	return PartyManager.members[0]


func _on_buy(entry: ShopEntry, price: int) -> void:
	if entry.stock == 0:
		NotificationBus.notification_requested.emit("Out of stock")
		return
	if GameState.gold < price:
		NotificationBus.notification_requested.emit("Not enough gold")
		return

	var leader := _get_leader()
	if leader == null:
		return
	if not leader.inventory.has_free_slot():
		NotificationBus.notification_requested.emit("%s's inventory is full!" % leader.resource.name)
		return

	if not GameState.spend_gold(price):
		return

	var instance: Item = entry.item._build_instance()
	if instance == null:
		push_error("Shop: item._build_instance() returned null")
		GameState.add_gold(price)
		return

	leader.inventory.add_item(instance)
	if not entry.is_infinite():
		entry.stock -= 1

	NotificationBus.notification_requested.emit("Bought %s for %d g" % [instance.get_item_name(), price])
	_rebuild()


func _on_sell(item: Item, price: int) -> void:
	var leader := _get_leader()
	if leader == null:
		return
	if not leader.inventory.remove_item(item):
		return
	GameState.add_gold(price)
	NotificationBus.notification_requested.emit("Sold %s for %d g" % [item.get_item_name(), price])
	_rebuild()
