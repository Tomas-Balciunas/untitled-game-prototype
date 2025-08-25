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

var level: int = 1
var current_experience: int = 0
var experience_to_next_level: int = 100
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
var job: Job
var gender: Gender
var race: Race
var inventory: Inventory

var equipment := {
	"weapon": null,
	"chest": null,
	"helmet": null,
	"boots": null,
	"gloves": null,
	"ring1": null,
	"ring2": null
}

func _init(res: CharacterResource) -> void:
	current_experience = 500
	stats = Stats.new()
	fill_stats(res)
	fill_attributes(res)
	resource = res
	
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
	
	stats.recalculate_stats(self, true, true)

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
	for e in effects:
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

func fill_attributes(res: CharacterResource):
	attributes = Attributes.new()
	attributes.add(res.attributes)
	if res.race:
		attributes.add(res.race.attributes)
	if res.gender:
		attributes.add(res.gender.attributes)
	if res.job:
		attributes.add(res.job.attributes)
	print(res.name, attributes.str)

func get_attack_power():
	pass

func get_experience_to_next_level() -> int:
	return 100 * level

func gain_experience() -> void:
	while current_experience >= experience_to_next_level:
		current_experience -= experience_to_next_level
		level_up()

func level_up() -> void:
	level += 1
	unspent_attribute_points += 1
	experience_to_next_level = get_experience_to_next_level()
	print("%s has reached level %d!" % [resource.name, level])

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
	stats.recalculate_stats(self, true, true)
	return true

func equip_item(item: GearInstance) -> bool:
	if not inventory.has_item(item):
		return false
	
	var slot_name = get_slot_name_for_item(item)

	if not slot_name:
		return false
		
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
		
	stats.recalculate_stats(self)
	
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
	stats.recalculate_stats(self)
	
	return true

func get_slot_name_for_item(item: GearInstance) -> String:
	match item.template.type:
		Item.ItemType.WEAPON: return "weapon"
		Item.ItemType.CHEST: return "chest"
		Item.ItemType.HELMET: return "helmet"
		Item.ItemType.BOOTS: return "boots"
		Item.ItemType.GLOVES: return "gloves"
		Item.ItemType.RING:
			if equipment["ring1"] == null:
				return "ring1"
			else:
				return "ring2"
		_: return ""

func to_dict() -> Dictionary:
	var equip_dict := {}
	for slot in equipment.keys():
		var item: GearInstance = equipment[slot]
		equip_dict[slot] = item.template.id if item else null

	return {
		"id": resource.id,
		"level": level,
		"xp": current_experience,
		"hp": stats.current_health,
		"mp": stats.current_mana,
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
		"equipment": equip_dict,
	}


static func from_dict(data: Dictionary) -> CharacterInstance:
	var res: CharacterResource = CharacterRegistry.get_character(data["id"])
	if res == null:
		push_error("Character resource not found for id %s" % data["id"])
		return null

	var inst := CharacterInstance.new(res)
	inst.level = data.get("level", 1)
	inst.current_experience = data.get("xp", 0)
	inst.unspent_attribute_points = data.get("unspent_points", 0)

	if data.has("attributes"):
		var a = data["attributes"]
		inst.attributes.str = a.get("str", inst.attributes.str)
		inst.attributes.iq  = a.get("iq", inst.attributes.iq)
		inst.attributes.pie = a.get("pie", inst.attributes.pie)
		inst.attributes.vit = a.get("vit", inst.attributes.vit)
		inst.attributes.dex = a.get("dex", inst.attributes.dex)
		inst.attributes.spd = a.get("spd", inst.attributes.spd)
		inst.attributes.luk = a.get("luk", inst.attributes.luk)

	inst.stats.current_health = data.get("hp", inst.stats.max_health)
	inst.stats.current_mana = data.get("mp", inst.stats.max_mana)

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

	return inst
