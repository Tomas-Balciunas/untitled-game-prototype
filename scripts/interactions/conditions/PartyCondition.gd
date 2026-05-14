extends InteractionCondition

class_name PartyCondition


enum Check { HAS_MEMBER, MISSING_MEMBER, HAS_SELF, MISSING_SELF, IS_FULL, HAS_FREE_SLOT, SIZE_AT_LEAST, SIZE_AT_MOST }


@export var check: Check = Check.HAS_MEMBER
@export var member_id: String = ""
@export var size: int = 0


func matches(c: BaseCharacterResource) -> bool:
	match check:
		Check.HAS_MEMBER:
			return PartyManager.has_member(member_id)
		Check.MISSING_MEMBER:
			return not PartyManager.has_member(member_id)
		Check.HAS_SELF:
			return PartyManager.has_member(c.id)
		Check.MISSING_SELF:
			return not PartyManager.has_member(c.id)
		Check.IS_FULL:
			return PartyManager.is_party_full()
		Check.HAS_FREE_SLOT:
			return not PartyManager.is_party_full()
		Check.SIZE_AT_LEAST:
			return PartyManager.members.size() >= size
		Check.SIZE_AT_MOST:
			return PartyManager.members.size() <= size

	return false


static func has_free_slot() -> PartyCondition:
	var c := PartyCondition.new()
	c.check = Check.HAS_FREE_SLOT
	return c


static func is_full() -> PartyCondition:
	var c := PartyCondition.new()
	c.check = Check.IS_FULL
	return c


static func has(mid: String) -> PartyCondition:
	var c := PartyCondition.new()
	c.check = Check.HAS_MEMBER
	c.member_id = mid
	return c


static func missing(mid: String) -> PartyCondition:
	var c := PartyCondition.new()
	c.check = Check.MISSING_MEMBER
	c.member_id = mid
	return c


static func has_self() -> PartyCondition:
	var c := PartyCondition.new()
	c.check = Check.HAS_SELF
	return c


static func missing_self() -> PartyCondition:
	var c := PartyCondition.new()
	c.check = Check.MISSING_SELF
	return c
