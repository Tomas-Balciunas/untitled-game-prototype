extends Resource

class_name InteractionController


func handle(c: BaseCharacterResource) -> void:
	if c.interactions == null:
		push_error("InteractionController.handle called with no interactions on %s" % c.id)
		return

	var entries := c.interactions.get_entries()

	var picked := _pick_entry(entries, c, false)
	if picked == null:
		picked = _pick_entry(entries, c, true)

	if picked == null:
		return

	var steps := _resolve_steps(picked)
	if steps.is_empty():
		push_warning("Interaction entry %s on %s has no steps" % [picked.id, c.id])
		return

	await EventManager.process_event(steps, c)


func _pick_entry(entries: Array[InteractionEntry], c: BaseCharacterResource, want_idle: bool) -> InteractionEntry:
	var candidates: Array[InteractionEntry] = []
	for entry: InteractionEntry in entries:
		if entry.idle != want_idle:
			continue
		if not entry.matches(c):
			continue
		candidates.append(entry)

	if candidates.is_empty():
		return null

	candidates.sort_custom(func (a: InteractionEntry, b: InteractionEntry) -> bool: return a.priority > b.priority)
	return candidates[0]


func _resolve_steps(entry: InteractionEntry) -> Array[EventStep]:
	if entry.random_pick and not entry.steps.is_empty():
		var picked: Array[EventStep] = [entry.steps.pick_random()]
		return picked

	return entry.steps
