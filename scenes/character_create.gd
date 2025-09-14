extends Control


@onready var job_ov: Label = $Overview/Job
@onready var race_ov: Label = $Overview/Race
@onready var gender_ov: Label = $Overview/Gender

@onready var classes_list: VBoxContainer = $Classes
@onready var races_list: VBoxContainer = $Races
@onready var genders_list: VBoxContainer = $Genders

var jobs: Array[Job] = []
var chosen_job: Job = null

var races: Array[Race] = []
var chosen_race: Race = null

var genders: Array[Gender] = []
var chosen_gender: Gender = null

var attributes: Attributes


func _ready() -> void:
	attributes = Attributes.new()
	
	jobs = JobRegistry.get_all()
	for j: Job in jobs:
		var btn = Button.new()
		btn.text = JobRegistry.type_to_string(j.name)
		btn.pressed.connect(_on_job_selected.bind(j))
		classes_list.add_child(btn)
	_on_job_selected(jobs[0])
	
	races = RaceRegistry.get_all()
	for r: Race in races:
		var btn = Button.new()
		btn.text = RaceRegistry.type_to_string(r.name)
		btn.pressed.connect(_on_race_selected.bind(r))
		races_list.add_child(btn)
	_on_race_selected(races[0])
	
	genders = GenderRegistry.get_all()
	for g: Gender in genders:
		var btn = Button.new()
		btn.text = GenderRegistry.type_to_string(g.name)
		btn.pressed.connect(_on_gender_selected.bind(g))
		genders_list.add_child(btn)
	_on_gender_selected(genders[0])
	

func _on_job_selected(j: Job) -> void:
	chosen_job = j
	job_ov.text = JobRegistry.type_to_string(j.name)
	
	
func _on_race_selected(r: Race) -> void:
	chosen_race = r
	race_ov.text = RaceRegistry.type_to_string(r.name)


func _on_gender_selected(g: Gender) -> void:
	chosen_gender = g
	gender_ov.text = GenderRegistry.type_to_string(g.name)


func _on_create_pressed() -> void:
	var res = CharacterResource.new()
	res.name = "Test"
	res.job = chosen_job
	
	await get_tree().change_scene_to_file("res://scenes/main.tscn")
	PartyManager.add_member(res)
