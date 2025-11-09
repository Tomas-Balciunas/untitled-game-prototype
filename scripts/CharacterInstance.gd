extends RefCounted

class_name CharacterInstance

signal mana_changed(old_mana: int, new_mana: int)
signal mana_consumed(amount: int, source: CharacterInstance)
signal mana_restored(amount: int, source: CharacterInstance)
signal died(ded: CharacterInstance)

var is_dead: bool = false
var is_main: bool = false

var body = null

var level: int = 1
var current_experience: int = 0
var unspent_attribute_points: int = 0
var resource: CharacterResource
var stats: Stats
var status_effects: Array = []
var turn_meter: int = 0
var learnt_skills: Array[Skill] = []
var effects: Array[Effect] = []
var gear_effects: Dictionary = {}
var damage_type: DamageTypes.Type
var attributes: Attributes
var level_up_attributes: Attributes
var starting_attributes: Attributes
var job: Job
var gender: Gender
var race: Race
var inventory: Inventory
var battle_events: Array[BattleEvent]

var equipment := {
	"weapon": null,
	"chest": null,
	"helmet": null,
	"boots": null,
	"gloves": null,
	"ring": null,
	"amulet": null
}

func _init(res: CharacterResource) -> void:
	resource = res
	
	if resource.character_body:
		body = resource.character_body
	
	level_up_attributes = Attributes.new()
	starting_attributes = Attributes.new()
	stats = Stats.new(res.base_stats)
	stats._owner = self
	fill_attributes()
	is_main = res.is_main
	current_experience = 5000
	
	inventory = Inventory.new()
	inventory.owner = self
	
	for item in res.default_items:
		if item is Gear:
			var gear := GearInstance.new(item)
			inventory.add_item(gear)
			
			continue
			
		if item is ConsumableItem:
			var cons := ConsumableInstance.new(item)
			inventory.add_item(cons)
			
			continue
		
		var inst := ItemInstance.new()
		inst.template = item
		inventory.add_item(inst)
	
	damage_type = res.default_damage_type
	
	job = res.job.duplicate(true)
	gender = res.gender.duplicate(true)
	race = res.race.duplicate(true)
	
	for skill in res.default_skills:
		if learnt_skills.has(skill):
			continue
		learnt_skills.append(skill)
		
	if res.job:
		for skill in res.job.skills:
			if learnt_skills.has(skill):
				continue
			learnt_skills.append(skill)
	
	for effect in res.default_effects:
		var inst := effect.duplicate()
		inst.on_apply(self)
		effects.append(inst)

	if res.job:
		for effect in res.job.effects:
			var inst := effect.duplicate()
			inst.on_apply(self)
			effects.append(inst)
	
	stats.recalculate_stats(true, true)

func set_current_health(new_health: int) -> void:
	var old := stats.current_health
	var new: float = clamp(new_health, 0, stats.get_final_stat(Stats.HEALTH))
	
	if new < old:
		stats.current_health = int(new)
		CharacterBus.character_damaged.emit(self, old - stats.current_health)
		var ints := resource.get_interactions()
		if ints:
			var text: String = ints.get_chatter("damaged")
			if text:
				CharacterBus.chat.emit(self, text)
			
	elif new > old:
		stats.current_health = int(new)
		CharacterBus.character_healed.emit(self, stats.current_health - old)
	
	CharacterBus.health_changed.emit(self, old, stats.current_health)
	
	if new == 0 and old > 0:
		stats.current_health = int(new)
		is_dead = true
		emit_signal("died", self)
		
func get_body() -> CharacterBody:
	if !body:
		push_warning("Missing body for %s" % resource.name)
		return null
	
	var inst := body.instantiate() as CharacterBody
	inst.body_owner = self
	return inst
	
func set_current_mana(new_mana: int) -> void:
	var old := stats.current_mana
	var new: float = clamp(new_mana, 0, stats.get_final_stat(Stats.MANA))
	
	if new < old:
		stats.current_mana = int(new)
		emit_signal("mana_consumed", old - stats.current_mana, self)
	elif new > old:
		stats.current_mana = int(new)
		emit_signal("mana_restored", stats.current_mana - old, self)
	emit_signal("mana_changed", old, stats.current_mana)

func prepare_for_battle() -> void:
	for e: Effect in effects:
		e.prepare_for_battle(self)

func cleanup_after_battle() -> void:
	for e in effects:
		e.cleanup_after_battle()

func apply_effect(effect: Effect, source: CharacterInstance = null) -> Effect:
	if effect._is_runtime_instance:
		push_warning("Applying an already-instantiated effect! Did you forget to pass the template?")

	var inst: Effect = effect if effect._is_instance else effect.duplicate(true)
	
	if source:
		inst.set_source(source)
	
	inst.on_apply(self)
	
	if not effect.should_append():
		return inst
	
	effects.append(inst)
	
	return inst
		
func remove_effect(effect: Effect) -> void:
	if effects.has(effect):
		effects.erase(effect)
		if effect.has_method("on_expire"):
			effect.on_expire(self)
		
func process_effects(trigger: String, ctx: ActionContext = null) -> void:
	for effect: Effect in effects.duplicate():
		if effect.has_method("on_trigger"):
			var event := TriggerEvent.new()
			event.actor = self
			event.trigger = trigger
			event.ctx = ctx
			effect.on_trigger(event)
		

func fill_attributes() -> void:
	attributes = Attributes.new()
	attributes.add(resource.attributes)
	if resource.race:
		attributes.add(resource.race.attributes)
	if resource.gender:
		attributes.add(resource.gender.attributes)
	if resource.job:
		attributes.add(resource.job.attributes)
	if level_up_attributes:
		attributes.add(level_up_attributes)
	if starting_attributes:
		attributes.add(starting_attributes)

func increase_attribute(attr: String) -> bool:
	if unspent_attribute_points <= 0:
		return false

	match attr:
		"STR": attributes.str += 1
		"IQ":  attributes.iq += 1
		"PIE": attributes.pie += 1
		"VIT": attributes.vit += 1
		"DEX": attributes.dex += 1
		"SPD": attributes.spd += 1
		"LUK": attributes.luk += 1
		_: return false

	unspent_attribute_points -= 1
	stats.recalculate_stats(true, true)
	return true

func equip_item(item: GearInstance) -> bool:
	var slot_name := get_slot_name_for_item(item)

	if not slot_name:
		return false
		
	if inventory.has_item(item):
		inventory.remove_item(item)
	
	if equipment[slot_name]:
		unequip_slot(slot_name)
		
	equipment[slot_name] = item
	var insts: Array = []
	
	for e in item.get_all_effects():
		var inst := apply_effect(e)
		insts.append(inst)
		
	gear_effects[slot_name] = insts
	
	for m in item.get_all_modifiers():
		stats.add_modifier(m)
		
	stats.recalculate_stats()
	
	return true

func unequip_slot(slot_name: String) -> bool:
	var item: GearInstance = equipment[slot_name]
	
	if not item:
		return false

	for inst: Effect in gear_effects.get(slot_name, []):
		remove_effect(inst)
	
	gear_effects.erase(slot_name)
		
	for m in item.get_all_modifiers():
		stats.remove_modifier(m)
	
	equipment[slot_name] = null
	inventory.add_item(item)
	stats.recalculate_stats()
	
	return true

func get_slot_name_for_item(item: GearInstance) -> String:
	match item.template.type:
		Item.ItemType.WEAPON: return "weapon"
		Item.ItemType.CHEST: return "chest"
		Item.ItemType.HELMET: return "helmet"
		Item.ItemType.BOOTS: return "boots"
		Item.ItemType.GLOVES: return "gloves"
		Item.ItemType.RING: return "ring"
		Item.ItemType.AMULET: return "amulet"
		_: return ""

func to_dict() -> Dictionary:
	var equip_dict := {}
	for slot: String in equipment.keys():
		var item: GearInstance = equipment[slot]
		if item:
			equip_dict[slot] = item.to_dict()
		
	var inventory_arr := []
	for slot: ItemInstance in inventory.slots:
		inventory_arr.append(slot.to_dict())
		
	var effect_arr := []
	for effect in effects:
		var is_gear_effect := false
		for key: String in gear_effects.keys():
			for gear_effect: Effect in gear_effects[key]:
				if effect == gear_effect:
					is_gear_effect = true
		if not is_gear_effect:
			effect_arr.append(effect.id)
			
	var skills_arr := []
	for skill: Skill in learnt_skills:
		if !skill.id:
			push_error("Skill %s has no id!" % skill.name)
			continue
		skills_arr.append(skill.id)

	return {
		"id": resource.id,
		"level": level,
		"xp": current_experience,
		"hp": stats.current_health,
		"mp": stats.current_mana,
		"race": race.name,
		"gender": gender.name,
		"job": job.name,
		"main": is_main,
		"unspent_points": unspent_attribute_points,
		"attributes": {
			"str": attributes.str,
			"iq": attributes.iq,
			"pie": attributes.pie,
			"vit": attributes.vit,
			"dex": attributes.dex,
			"spd": attributes.spd,
			"luk": attributes.luk
		},
		"level_up_attributes": {
			"str": level_up_attributes.str,
			"iq": level_up_attributes.iq,
			"pie": level_up_attributes.pie,
			"vit": level_up_attributes.vit,
			"dex": level_up_attributes.dex,
			"spd": level_up_attributes.spd,
			"luk": level_up_attributes.luk
		},
		"starting_attributes": {
			"str": starting_attributes.str,
			"iq": starting_attributes.iq,
			"pie": starting_attributes.pie,
			"vit": starting_attributes.vit,
			"dex": starting_attributes.dex,
			"spd": starting_attributes.spd,
			"luk": starting_attributes.luk
		},
		"equipment": equip_dict,
		"inventory": inventory_arr,
		"effects": effect_arr,
		"skills": skills_arr
	}


static func from_dict(data: Dictionary) -> CharacterInstance:
	var res: CharacterResource = CharacterRegistry.get_character(data["id"])
	if res == null:
		push_error("Character resource not found for id %s" % data["id"])
		return null

	res.race = RaceRegistry.get_by_name(RaceRegistry.type_to_string(data["race"])) 
	res.gender = GenderRegistry.get_by_name(GenderRegistry.type_to_string(data["gender"])) 
	res.job = JobRegistry.get_by_name(JobRegistry.type_to_string(data["job"])) 
	var inst := CharacterInstance.new(res)
	
	if data["main"]:
		inst.is_main = data["main"]
	
	inst.level = data.get("level", 1)
	inst.current_experience = data.get("xp", 0)
	inst.unspent_attribute_points = data.get("unspent_points", 0)

	if data.has("level_up_attributes"):
		var a: Dictionary = data["level_up_attributes"]
		inst.level_up_attributes.str = a.get("str")
		inst.level_up_attributes.iq  = a.get("iq")
		inst.level_up_attributes.pie = a.get("pie")
		inst.level_up_attributes.vit = a.get("vit")
		inst.level_up_attributes.dex = a.get("dex")
		inst.level_up_attributes.spd = a.get("spd")
		inst.level_up_attributes.luk = a.get("luk")
		
	if data.has("attributes"):
		var a: Dictionary = data["attributes"]
		inst.attributes.str = a.get("str", inst.attributes.str)
		inst.attributes.iq  = a.get("iq", inst.attributes.iq)
		inst.attributes.pie = a.get("pie", inst.attributes.pie)
		inst.attributes.vit = a.get("vit", inst.attributes.vit)
		inst.attributes.dex = a.get("dex", inst.attributes.dex)
		inst.attributes.spd = a.get("spd", inst.attributes.spd)
		inst.attributes.luk = a.get("luk", inst.attributes.luk)
	
	if data.has("starting_attributes"):
		var a: Dictionary = data["starting_attributes"]
		inst.starting_attributes.str = a.get("str", inst.starting_attributes.str)
		inst.starting_attributes.iq  = a.get("iq", inst.starting_attributes.iq)
		inst.starting_attributes.pie = a.get("pie", inst.starting_attributes.pie)
		inst.starting_attributes.vit = a.get("vit", inst.starting_attributes.vit)
		inst.starting_attributes.dex = a.get("dex", inst.starting_attributes.dex)
		inst.starting_attributes.spd = a.get("spd", inst.starting_attributes.spd)
		inst.starting_attributes.luk = a.get("luk", inst.starting_attributes.luk)

	inst.stats.current_health = data.get("hp", inst.stats.get_final_stat(Stats.HEALTH))
	inst.stats.current_mana = data.get("mp", inst.stats.get_final_stat(Stats.MANA))

	if data.has("inventory"):
		inst.inventory.slots = []
		for item_data: Dictionary in data["inventory"]:
			var id: String = item_data.get("resource")
			var item_res := ItemsRegistry.get_item(id)
			
			if not item_res:
				push_error("Item not found! %s" % id)
				continue
			
			if item_res is Gear:
				var gear := GearInstance.from_dict(item_data)
				inst.inventory.add_item(gear)
			
			if item_res is ConsumableItem:
				var cons := ConsumableInstance.from_dict(item_data)
				inst.inventory.add_item(cons)
				
	if data.has("effects"):
		inst.effects = []
		for effect_id: String in data["effects"]:
			var effect := EffectRegistry.get_effect(effect_id)
			if not effect:
				push_error("Effect not found: %s" % effect_id)
				continue
			inst.apply_effect(effect)
			
	if data.has("skills"):
		inst.learnt_skills = []
		for skill_id: String in data["skills"]:
			var skill := SkillRegistry.get_skill(skill_id)
			if not skill:
				push_error("Skill not found: %s" % skill_id)
				continue
			inst.learnt_skills.append(skill)

	if data.has("equipment"):
		for slot: String in data["equipment"].keys():
			var item_dict: Dictionary = data["equipment"][slot]
			if item_dict != null:
				var gear_inst := GearInstance.from_dict(item_dict)
				if gear_inst and gear_inst is GearInstance:
					inst.equip_item(gear_inst)
					
	inst.stats.recalculate_stats()
	return inst
