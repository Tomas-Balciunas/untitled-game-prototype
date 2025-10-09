extends RefCounted

class_name CharacterInstance

signal health_changed(old_health, new_health)
signal mana_changed(old_mana, new_mana)
signal damaged(amount: int, source: CharacterInstance)
signal healed(amount: int)
signal mana_consumed(amount: int, source: CharacterInstance)
signal mana_restored(amount: int, source: CharacterInstance)
signal died(ded: CharacterInstance)

var is_dead: bool = false
var is_main: bool = false

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
	level_up_attributes = Attributes.new()
	starting_attributes = Attributes.new()
	stats = Stats.new()
	stats._owner = self
	fill_stats(res)
	fill_attributes()
	is_main = res.is_main
	current_experience = 5000
	
	inventory = Inventory.new()
	
	for item in res.default_items:
		if item is Gear:
			var gear = GearInstance.new()
			gear.template = item
			gear.effects = item.effects
			gear.modifiers = item.modifiers
			inventory.add_item(gear)
			
			continue
			
		if item is ConsumableItem:
			var cons = ConsumableInstance.new()
			cons.template = item
			cons.effects = item.effects
			inventory.add_item(cons)
			
			continue
		
		var inst = ItemInstance.new()
		inst.template = item
		inventory.add_item(inst)
	
	damage_type = res.default_damage_type
	
	job = res.job
	gender = res.gender
	race = res.race
	
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
		var inst = effect.duplicate()
		inst.on_apply(self)
		effects.append(inst)

	if res.job:
		for effect in res.job.effects:
			var inst = effect.duplicate()
			inst.on_apply(self)
			effects.append(inst)
	
	stats.recalculate_stats(true, true)

func set_current_health(new_health: int) -> void:
	var old = stats.current_health
	var new = clamp(new_health, 0, stats.max_health)
	
	if new < old:
		stats.current_health = new
		emit_signal("damaged", old - stats.current_health, self)
	elif new > old:
		stats.current_health = new
		print("%s was healed for %s" % [resource.name, stats.current_health - old])
		emit_signal("healed", stats.current_health - old)
	emit_signal("health_changed", old, stats.current_health)
	if new == 0 and old > 0:
		stats.current_health = new
		is_dead = true
		print("%s is dead" % resource.name)
		emit_signal("died", self)
	print("%s HP %s/%s" % [resource.name, stats.current_health, stats.max_health])
	
func set_current_mana(new_mana: int) -> void:
	var old = stats.current_mana
	var new = clamp(new_mana, 0, stats.max_mana)
	
	if new < old:
		stats.current_mana = new
		emit_signal("mana_consumed", old - stats.current_mana, self)
	elif new > old:
		stats.current_mana = new
		emit_signal("mana_restored", stats.current_mana - old, self)
	emit_signal("mana_changed", old, stats.current_mana)
	print("%s MP %s/%s" % [resource.name, stats.current_mana, stats.max_mana])

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
	for effect in effects.duplicate():
		if effect.has_method("on_trigger"):
			var event = TriggerEvent.new()
			event.actor = self
			event.trigger = trigger
			event.ctx = ctx
			effect.on_trigger(event)
		
func fill_stats(res: CharacterResource):
	stats.base_attack = res.attack_power
	stats.current_health = res.health_points
	stats.base_health = res.health_points
	stats.current_mana = res.mana_points
	stats.base_mana = res.mana_points
	stats.base_defense = res.defense
	stats.base_speed = res.speed

func fill_attributes():
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

func get_attack_power():
	pass

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
	var slot_name = get_slot_name_for_item(item)

	if not slot_name:
		return false
		
	if inventory.has_item(item):
		inventory.remove_item(item)
	
	if equipment[slot_name]:
		unequip_slot(slot_name)
		
	equipment[slot_name] = item
	var insts: Array = []
	
	for e in item.get_all_effects():
		var inst = apply_effect(e)
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

	for inst in gear_effects.get(slot_name, []):
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
	for slot in equipment.keys():
		var item: GearInstance = equipment[slot]
		equip_dict[slot] = item.template.id if item else null
		
	var inventory_arr := []
	for slot: ItemInstance in inventory.slots:
		inventory_arr.append(slot.template.id)
		
	var effect_arr := []
	for effect in effects:
		var is_gear_effect := false
		for key in gear_effects.keys():
			for gear_effect in gear_effects[key]:
				if effect == gear_effect:
					is_gear_effect = true
		if not is_gear_effect:
			effect_arr.append(effect.id)

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
		"effects": effect_arr
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
		var a = data["level_up_attributes"]
		inst.level_up_attributes.str = a.get("str")
		inst.level_up_attributes.iq  = a.get("iq")
		inst.level_up_attributes.pie = a.get("pie")
		inst.level_up_attributes.vit = a.get("vit")
		inst.level_up_attributes.dex = a.get("dex")
		inst.level_up_attributes.spd = a.get("spd")
		inst.level_up_attributes.luk = a.get("luk")
		
	if data.has("attributes"):
		var a = data["attributes"]
		inst.attributes.str = a.get("str", inst.attributes.str)
		inst.attributes.iq  = a.get("iq", inst.attributes.iq)
		inst.attributes.pie = a.get("pie", inst.attributes.pie)
		inst.attributes.vit = a.get("vit", inst.attributes.vit)
		inst.attributes.dex = a.get("dex", inst.attributes.dex)
		inst.attributes.spd = a.get("spd", inst.attributes.spd)
		inst.attributes.luk = a.get("luk", inst.attributes.luk)
	
	if data.has("starting_attributes"):
		var a = data["starting_attributes"]
		inst.starting_attributes.str = a.get("str", inst.starting_attributes.str)
		inst.starting_attributes.iq  = a.get("iq", inst.starting_attributes.iq)
		inst.starting_attributes.pie = a.get("pie", inst.starting_attributes.pie)
		inst.starting_attributes.vit = a.get("vit", inst.starting_attributes.vit)
		inst.starting_attributes.dex = a.get("dex", inst.starting_attributes.dex)
		inst.starting_attributes.spd = a.get("spd", inst.starting_attributes.spd)
		inst.starting_attributes.luk = a.get("luk", inst.starting_attributes.luk)

	inst.stats.current_health = data.get("hp", inst.stats.max_health)
	inst.stats.current_mana = data.get("mp", inst.stats.max_mana)

	if data.has("inventory"):
		inst.inventory.slots = []
		for id: String in data["inventory"]:
			var item_res = ItemsRegistry.get_item(id)
			
			if not item_res:
				push_error("Item not found! %s" % id)
			
			if item_res is Gear:
				var gear = GearInstance.new()
				gear.template = item_res
				gear.effects = item_res.effects
				gear.modifiers = item_res.modifiers
				inst.inventory.add_item(gear)
			
			if item_res is ConsumableItem:
				var cons = ConsumableInstance.new()
				cons.template = item_res
				cons.effects = item_res.effects
				inst.inventory.add_item(cons)
				
	if data.has("effects"):
		inst.effects = []
		for effect_id in data["effects"]:
			var effect = EffectRegistry.get_effect(effect_id)
			if not effect:
				push_error("Effect not found: %s" % effect_id)
			inst.apply_effect(effect)

	if data.has("equipment"):
		for slot in data["equipment"].keys():
			var item_id = data["equipment"][slot]
			if item_id != null:
				var gear_res = ItemsRegistry.get_item(item_id)
				if gear_res and gear_res is Gear:
					var gear = GearInstance.new()
					gear.template = gear_res
					gear.effects = gear_res.effects
					gear.modifiers = gear_res.modifiers
					inst.equip_item(gear)
					
	inst.stats.recalculate_stats()
	return inst
