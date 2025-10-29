extends EventStep
class_name TrapStep

var id: String
var damage: int

func _init(data: Dictionary) -> void:
	id = data.get("id", "")
	damage = data.get("damage", 10)

func run(_manager: Node) -> void:
	var target := PartyManager.members[0]
	var attacker = CharacterResource.new()
	attacker.name = "Poison Dart"
	var poison = PoisonOnHit.new()
	poison.duration_turns = 3
	
	
	
	var act = AttackAction.new()
	act.defender = target
	act.attacker = CharacterInstance.new(attacker)
	act.base_value = damage
	act.actively_cast = true
	act.effects.append(poison)
	
	
	DamageResolver.apply_attack(act)
