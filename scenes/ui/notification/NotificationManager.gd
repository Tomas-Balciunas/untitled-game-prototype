extends Node

const NotificationScene = preload("uid://deto7uvy3fuoj")
const node_name = "NotificationScene"

func _ready() -> void:
	NotificationBus.notification_requested.connect(show_notification)

func show_notification(notif: String) -> void:
	var main: Node3D = get_tree().get_root().get_node("Main")
	var notification_node: PanelContainer = main.get_node_or_null(node_name)
	
	if !notification_node:
		var instance: PanelContainer = NotificationScene.instantiate()
		instance.name = node_name
		notification_node = instance
		main.add_child(instance)
		
	notification_node.add_notification(notif)
