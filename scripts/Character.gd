extends Entity

class_name Character

signal mana_consumed(amount: int, source: Character)
signal mana_restored(amount: int, source: Character)
signal died(ded: Character)

var is_dead: bool = false
var is_main: bool = false

var body: PackedScene = null

var level: int = 1
var current_experience: int = 0
var unspent_attribute_points: int = 0
var resource: CharacterResource
var stats: Stats
var computed_stats: Stats
var base_stats: Stats
var state: CharacterState
var action_value: float = 0
var learnt_skills: Array[Skill] = []
var effects: Array[Effect] = []
var gear_effects: Dictionary = {}
var damage_type: DamageTypes.Type
var attributes: Attributes
var level_up_attributes: Attributes
var starting_attributes: Attributes
var job: Job
var race: Race
var inventory: Inventory
var battle_events: Array[BattleEvent]
var interactions: CharacterInteraction
var interaction_controller: InteractionController
var chatter: CharacterChatter
var experience_manager: ExperienceManager = null

var equipment: Equipment = null

func _init(res: CharacterResource, override_level: int = 0) -> void:
	resource = res
	resource._setup_character()
	
	job = res.job.duplicate(true)
	race = res.race.duplicate(true)
	
	if resource.character_body:
		body = resource.character_body
		
	if resource.interactions:
		interactions = resource.interactions
		
	if resource.interaction_controller:
		interaction_controller = resource.interaction_controller

	if resource.chatter:
		chatter = resource.chatter
	
	level_up_attributes = Attributes.new()
	starting_attributes = res.attributes.duplicate(true)
	fill_attributes()
	
	stats = res.base_stats.duplicate(true)
	base_stats = res.base_stats.duplicate(true)
	computed_stats = base_stats.duplicate(true)
	
	state = CharacterState.new(stats)
	
	is_main = res.is_main
	
	if override_level > 0:
		level = override_level
	else:
		level = max(1, res.level)
	
	experience_manager = res.experience_manager
	experience_manager.set_character_level(self, level)
	
	equipment = Equipment.new(self)
	inventory = Inventory.new()
	inventory.owner = self
	
	for item in res.default_items:
		if item is GearResource:
			var gear = item._build_instance()
			inventory.add_item(gear)
			
			continue
			
		if item is ConsumableItem:
			var cons: Consumable = item._build_instance()
			inventory.add_item(cons)
			
			continue
		
		#var inst := Item.new()
		#inst.template = item
		#inventory.add_item(inst)
	
	damage_type = res.default_damage_type
	
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
		apply_effect(effect, CharacterSource.new(self))

	if res.job:
		for effect in res.job.effects:
			apply_effect(effect, CharacterSource.new(self))
	
	StatCalculator.recalculate_all_stats(self)
	state.current_health = stats.health
	state.current_mana = stats.mana
	state.current_sp = stats.sp

func can_be_damaged() -> bool:
	return true

func can_be_healed() -> bool:
	return true

func can_receive_effects() -> bool:
	return true

func set_current_health(new_health: int, damage_event: DamageInstance = null) -> void:
	var old: int = state.current_health
	var new: float = clamp(new_health, 0, stats.health)
	
	if new < old:
		state.current_health = int(new)
			
	elif new > old:
		state.current_health = int(new)
		CharacterBus.character_healed.emit(self, state.current_health - old)
	
	CharacterBus.stat_changed.emit(self, Stats.StatRef.HEALTH)
	
	if new == 0 and old > 0:
		state.current_health = int(new)
		is_dead = true
		emit_signal("died", self)
	
	if damage_event:
		CharacterBus.character_damaged.emit(self, damage_event)
	
	CharacterBus.health_changed.emit(self, old, new)
		
func get_body() -> CharacterBody:
	if !body:
		push_warning("Missing body for %s" % resource.name)
		return null
	
	var inst := body.instantiate() as CharacterBody
	inst.body_owner = self
	return inst
	
func set_current_mana(new_mana: int) -> void:
	var old: int = state.current_mana
	var new: float = clamp(new_mana, 0, stats.mana)
	
	if new < old:
		state.current_mana = int(new)
		emit_signal("mana_consumed", old - state.current_mana, self)
	elif new > old:
		state.current_mana = int(new)
		emit_signal("mana_restored", state.current_mana - old, self)
	
	CharacterBus.stat_changed.emit(self, Stats.StatRef.MANA)

func set_current_sp(new_sp: int) -> void:
	var old: int = state.current_sp
	var new: float = clamp(new_sp, 0, stats.sp)
	
	if new < old:
		state.current_sp = int(new)
	elif new > old:
		state.current_sp = int(new)
	
	CharacterBus.stat_changed.emit(self, Stats.StatRef.SP)

func prepare_for_battle() -> void:
	for e: Effect in effects:
		e.prepare_for_battle()

func on_turn_start() -> void:
	var sorted: Array[Effect] = effects.duplicate()
	sorted.sort_custom(EffectRunner._sort_by_priority)
	
	for e: Effect in sorted:
		e.on_turn_start()

func on_turn_end() -> void:
	var sorted: Array[Effect] = effects.duplicate()
	sorted.sort_custom(EffectRunner._sort_by_priority)
	
	for e: Effect in sorted:
		e.on_turn_end()

func cleanup_after_battle() -> void:
	for effect: Effect in effects.duplicate():
		if effect.expires_after_battle:
			effects.erase(effect)

	for effect in effects:
		effect.on_battle_end()

	state.temporary_modifiers = []
	StatCalculator.recalculate_all_stats(self)

func apply_effect(effect: Effect, source: ContextSource) -> Effect:
	var inst: Effect = effect.duplicate(true)
	inst.set_owner(self)
	inst.set_source(source)
	inst.remaining_turns = inst.duration_turns
	inst.on_apply()
	
	effects.append(inst)
	EffectRunner.subscribe(inst)

	return inst

func remove_effect(effect: Effect) -> void:
	if effects.has(effect):
		EffectRunner.unsubscribe(effect)
		effects.erase(effect)


func fill_attributes() -> void:
	attributes = Attributes.new()
	attributes.add(resource.attributes)
	
	if resource.race:
		attributes.add(resource.race.attributes)
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

func game_save() -> Dictionary:
	var equip_dict := {}
	for item: Gear in equipment.get_all_equipment():
		if item:
			var slot := ItemTypes.gear_type_to_string(item.get_gear_type())
			equip_dict[slot] = item.game_save()

	var inventory_arr := []
	for item: Item in inventory.get_all_items():
		inventory_arr.append(item.game_save())

	# Skip effects that came from equipped gear — they'll be re-applied
	# when equipment is re-equipped on load.
	var gear_effect_set := {}
	for key: int in gear_effects.keys():
		for ge: Effect in gear_effects[key]:
			gear_effect_set[ge.get_instance_id()] = true

	var effect_arr := []
	for effect: Effect in effects:
		if gear_effect_set.has(effect.get_instance_id()):
			continue
		effect_arr.append(effect.game_save())

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
		"hp": state.current_health,
		"mp": state.current_mana,
		"sp": state.current_sp,
		"damage_type": damage_type,
		"race": race.name,
		"job": job.name,
		"main": is_main,
		"unspent_points": unspent_attribute_points,
		"attributes": attributes.game_save(),
		"level_up_attributes": level_up_attributes.game_save(),
		"starting_attributes": starting_attributes.game_save(),
		"equipment": equip_dict,
		"inventory": inventory_arr,
		"effects": effect_arr,
		"skills": skills_arr
	}


static func create_from_save(data: Dictionary) -> Character:
	var res: CharacterResource = CharacterRegistry.get_character(data["id"])
	if res == null:
		push_error("Character resource not found for id %s" % data["id"])
		return null

	res.race = RaceRegistry.get_by_name(RaceRegistry.type_to_string(data["race"]))
	res.job = JobRegistry.get_by_name(JobRegistry.type_to_string(data["job"]))
	var inst := Character.new(res)
	inst.game_load(data)
	return inst


func game_load(data: Dictionary) -> void:
	if data.has("main"):
		is_main = data["main"]

	level = data.get("level", 1)
	current_experience = data.get("xp", 0)
	unspent_attribute_points = data.get("unspent_points", 0)
	damage_type = data.get("damage_type", damage_type) as DamageTypes.Type

	if data.has("level_up_attributes"):
		level_up_attributes.game_load(data["level_up_attributes"])

	if data.has("attributes"):
		attributes.game_load(data["attributes"])

	if data.has("starting_attributes"):
		starting_attributes.game_load(data["starting_attributes"])

	# Reset effects gathered during _init — saved effects are the source of truth.
	for e: Effect in effects.duplicate():
		EffectRunner.unsubscribe(e)
	effects = []
	gear_effects = {}

	if data.has("skills"):
		learnt_skills = []
		for skill_id: String in data["skills"]:
			var skill := SkillRegistry.get_skill(skill_id)
			if not skill:
				push_error("Skill not found: %s" % skill_id)
				continue
			learnt_skills.append(skill)

	if data.has("inventory"):
		inventory.slots = []
		for item_data: Dictionary in data["inventory"]:
			var item := Item.create_from_save(item_data)
			if item:
				inventory.add_item(item)

	if data.has("equipment"):
		for slot: String in data["equipment"].keys():
			var item_dict: Dictionary = data["equipment"][slot]
			var gear_inst := Gear.create_from_save(item_dict)
			if gear_inst:
				inventory.add_item(gear_inst)
				equipment.equip_item(gear_inst)

	StatCalculator.recalculate_all_stats(self)
	state.current_health = data.get("hp", stats.health)
	state.current_mana = data.get("mp", stats.mana)
	state.current_sp = data.get("sp", stats.sp)


# Two-phase load: effects are restored *after* all party characters exist,
# so cross-character source references (e.g. ally A's skill poisons ally B)
# can resolve via PartyManager.
func game_load_effects(data: Dictionary) -> void:
	if not data.has("effects"):
		return
	for entry: Dictionary in data["effects"]:
		var eff := Effect.create_from_save(entry)
		if not eff:
			continue
		# Wire up the effect as if it were already applied — no on_apply.
		# Owner must be set before game_load so subclasses can use it to
		# re-wire side effects (e.g. StatBonusEffect re-adds its modifier).
		eff.set_owner(self)
		eff.set_source(CharacterSource.new(self))
		effects.append(eff)
		EffectRunner.subscribe(eff)
		# game_load may override source with the persisted one (TrapSource, etc.)
		eff.game_load(entry)
