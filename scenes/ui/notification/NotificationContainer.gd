extends PanelContainer

@onready var notification_box: VBoxContainer = %NotificationBox
const NotificationLine = preload("uid://bcmw8nisgq2m8")


func _ready() -> void:
	notification_box.child_exiting_tree.connect(_on_child_exited)

func add_notification(notif: String) -> void:
	var line: Label = NotificationLine.instantiate()
	line.set_notification(notif)
	
	notification_box.add_child(line)

func _on_child_exited(_child: Node) -> void:
	if notification_box.get_child_count() == 1:
		queue_free()
		
