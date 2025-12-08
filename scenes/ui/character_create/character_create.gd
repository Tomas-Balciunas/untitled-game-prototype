extends Control

const MAX_POINTS := 10
const MC = preload("uid://dvky7cvffgf22")

@onready var job_ov: Label = $Overview/Job
@onready var race_ov: Label = $Overview/Race
@onready var gender_ov: Label = $Overview/Gender

@onready var classes_list: VBoxContainer = $Classes
@onready var races_list: VBoxContainer = $Races
@onready var genders_list: VBoxContainer = $Genders

@onready var str_attr: Label = $Attributes/Values/STR/Value
@onready var iq_attr: Label  = $Attributes/Values/IQ/Value
@onready var pie_attr: Label = $Attributes/Values/PIE/Value
@onready var vit_attr: Label = $Attributes/Values/VIT/Value
@onready var dex_attr: Label = $Attributes/Values/DEX/Value
@onready var spd_attr: Label = $Attributes/Values/SPD/Value
@onready var luk_attr: Label = $Attributes/Values/LUK/Value

@onready var str_dec: Button = $Attributes/Values/STR/Dec
@onready var str_inc: Button = $Attributes/Values/STR/Inc

@onready var iq_dec: Button  = $Attributes/Values/IQ/Dec
@onready var iq_inc: Button  = $Attributes/Values/IQ/Inc

@onready var pie_dec: Button = $Attributes/Values/PIE/Dec
@onready var pie_inc: Button = $Attributes/Values/PIE/Inc

@onready var vit_dec: Button = $Attributes/Values/VIT/Dec
@onready var vit_inc: Button = $Attributes/Values/VIT/Inc

@onready var dex_dec: Button = $Attributes/Values/DEX/Dec
@onready var dex_inc: Button = $Attributes/Values/DEX/Inc

@onready var spd_dec: Button = $Attributes/Values/SPD/Dec
@onready var spd_inc: Button = $Attributes/Values/SPD/Inc

@onready var luk_dec: Button = $Attributes/Values/LUK/Dec
@onready var luk_inc: Button = $Attributes/Values/LUK/Inc

@onready var points_display: Label = $Points

var jobs: Array[Job] = []
var chosen_job: Job = null

var races: Array[Race] = []
var chosen_race: Race = null

var genders: Array[Gender] = []
var chosen_gender: Gender = null

var chosen_attributes: Attributes = null
var display_attributes: Attributes = null

var points: int = 0


func _ready() -> void:
	chosen_attributes = Attributes.new()
	points = MAX_POINTS
	
	jobs = JobRegistry.get_all()
	for j: Job in jobs:
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = JobRegistry.type_to_string(j.name)
		btn.pressed.connect(_on_job_selected.bind(j))
		classes_list.add_child(btn)
	_on_job_selected(jobs[0])
	
	races = RaceRegistry.get_all()
	for r: Race in races:
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = RaceRegistry.type_to_string(r.name)
		btn.pressed.connect(_on_race_selected.bind(r))
		races_list.add_child(btn)
	_on_race_selected(races[0])
	
	genders = GenderRegistry.get_all()
	for g: Gender in genders:
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = GenderRegistry.type_to_string(g.name)
		btn.pressed.connect(_on_gender_selected.bind(g))
		genders_list.add_child(btn)
	_on_gender_selected(genders[0])
	update_attributes()
	_setup_attribute_buttons()
	update_points()


func _setup_attribute_buttons() -> void:
	str_dec.pressed.connect(_on_attribute_changed.bind("STR", -1))
	str_inc.pressed.connect(_on_attribute_changed.bind("STR", 1))

	iq_dec.pressed.connect(_on_attribute_changed.bind("IQ", -1))
	iq_inc.pressed.connect(_on_attribute_changed.bind("IQ", 1))

	pie_dec.pressed.connect(_on_attribute_changed.bind("PIE", -1))
	pie_inc.pressed.connect(_on_attribute_changed.bind("PIE", 1))

	vit_dec.pressed.connect(_on_attribute_changed.bind("VIT", -1))
	vit_inc.pressed.connect(_on_attribute_changed.bind("VIT", 1))

	dex_dec.pressed.connect(_on_attribute_changed.bind("DEX", -1))
	dex_inc.pressed.connect(_on_attribute_changed.bind("DEX", 1))

	spd_dec.pressed.connect(_on_attribute_changed.bind("SPD", -1))
	spd_inc.pressed.connect(_on_attribute_changed.bind("SPD", 1))

	luk_dec.pressed.connect(_on_attribute_changed.bind("LUK", -1))
	luk_inc.pressed.connect(_on_attribute_changed.bind("LUK", 1))

	_update_attribute_labels()
	
func _on_attribute_changed(attr_name: String, delta: int) -> void:
	match attr_name:
		"STR":
			chosen_attributes.str = whatever(delta, chosen_attributes.str)
		"IQ":
			chosen_attributes.iq = whatever(delta, chosen_attributes.iq)
		"PIE":
			chosen_attributes.pie = whatever(delta, chosen_attributes.pie)
		"VIT":
			chosen_attributes.vit = whatever(delta, chosen_attributes.vit)
		"DEX":
			chosen_attributes.dex = whatever(delta, chosen_attributes.dex)
		"SPD":
			chosen_attributes.spd = whatever(delta, chosen_attributes.spd)
		"LUK":
			chosen_attributes.luk = whatever(delta, chosen_attributes.luk)

	chosen_attributes.str = max(chosen_attributes.str, 0)
	chosen_attributes.iq = max(chosen_attributes.iq, 0)
	chosen_attributes.pie = max(chosen_attributes.pie, 0)
	chosen_attributes.vit = max(chosen_attributes.vit, 0)
	chosen_attributes.dex = max(chosen_attributes.dex, 0)
	chosen_attributes.spd = max(chosen_attributes.spd, 0)
	chosen_attributes.luk = max(chosen_attributes.luk, 0)
	
	update_attributes()
	_update_attribute_labels()
	update_points()
	
func whatever(delta: int, attr: int) -> int:
	if delta > 0 and points <= 0:
		return attr
	if delta < 0 and attr <= 0:
		return attr

	attr += delta
	points = clamp(points - delta, 0, MAX_POINTS)
	return attr
	
func _update_attribute_labels() -> void:
	str_attr.text = str(display_attributes.strength)
	iq_attr.text  = str(display_attributes.intelligence)
	pie_attr.text = str(display_attributes.piety)
	vit_attr.text = str(display_attributes.vitality)
	dex_attr.text = str(display_attributes.dexterity)
	spd_attr.text = str(display_attributes.speed)
	luk_attr.text = str(display_attributes.luck)
	

func _on_job_selected(j: Job) -> void:
	chosen_job = j
	job_ov.text = JobRegistry.type_to_string(j.name)
	update_attributes()
	_update_attribute_labels()
	
	
func _on_race_selected(r: Race) -> void:
	chosen_race = r
	race_ov.text = RaceRegistry.type_to_string(r.name)
	update_attributes()
	_update_attribute_labels()


func _on_gender_selected(g: Gender) -> void:
	chosen_gender = g
	gender_ov.text = GenderRegistry.type_to_string(g.name)
	update_attributes()
	_update_attribute_labels()
	

func update_attributes() -> void:
	var attr := Attributes.new()
	if chosen_gender:
		attr.add(chosen_gender.attributes)
	
	if chosen_job:
		attr.add(chosen_job.attributes)
		
	if chosen_race:
		attr.add(chosen_race.attributes)
		
	if chosen_attributes:
		attr.add(chosen_attributes)
		
	display_attributes = attr

func _on_create_pressed() -> void:
	var res := MC
	res.name = "Test"
	res.job = chosen_job
	res.gender = chosen_gender
	res.race = chosen_race
	res.attributes = Attributes.new()
	res.is_main = true
	var inst := PartyManager.add_member(res)
	
	if !inst:
		push_error("something went horribly wrong - created character instance is null, check party size?")
	
	inst.starting_attributes = chosen_attributes
	inst.fill_attributes()
	StatCalculator.recalculate_all_stats(inst)
	
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	

func update_points() -> void:
	points_display.text = "Points left: %s" % points
