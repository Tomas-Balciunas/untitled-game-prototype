extends RefCounted
class_name KeyFactory

const SEAL_WORDS: Array[String] = ["Ossuary", "Vault", "Reliquary", "Cellar", "Catacomb"]

const DESCRIPTION := "Opens a specific seal in this dungeon."


static func key_id(map_id: String, door_id: String) -> String:
	return "key_%s_%s" % [map_id, door_id]


static func seal_word(ordinal: int) -> String:
	return SEAL_WORDS[ordinal % SEAL_WORDS.size()]


static func key_name(ordinal: int) -> String:
	return "%s Key" % seal_word(ordinal)


static func build(id: String, display_name: String) -> QuestItemResource:
	var res := QuestItemResource.new()
	res.id = id
	res.name = display_name
	res.description = DESCRIPTION
	res.value = 0

	return res


static func rebuild(id: String, display_name: String) -> QuestItemResource:
	return build(id, display_name)
