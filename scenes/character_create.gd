extends Control

@onready var job_ov: Label = $Overview/Job

@onready var job_btn: OptionButton = $JobButton
var jobs: Array[Job] = []
var chosen_job: Job = null


func _ready() -> void:
	job_ov.text = "-"
	
	jobs = JobRegistry.get_all()
	for j: Job in jobs:
		job_btn.add_item(JobRegistry.type_to_string(j.name))


func _on_option_button_item_selected(index: int) -> void:
	chosen_job = jobs[index]
	job_ov.text = JobRegistry.type_to_string(jobs[index].name)


func _on_create_pressed() -> void:
	var res = CharacterResource.new()
	res.name = "Test"
	res.job = chosen_job
	
	await get_tree().change_scene_to_file("res://scenes/main.tscn")
	PartyManager.add_member(res)
