class_name Journal
extends RefCounted

## What happened, and why — the only place in the game allowed to answer the second.
##
## §15 calls this the most important screen in the game and §8 makes it the third
## feedback register: IMMEDIATE is the act confirmed as you do it, AMBIENT is the
## world quietly changing its mind, and NARRATED is this. All three are required,
## and most systemic games ship the first two, which is why their players never
## feel their choices mattered.
##
## **Push the ambient, pull the attribution.** Nothing in the world ever tells the
## player that they caused something — Maddox not knowing it was you is the whole
## pleasure of it. So the causal chain lives here, behind a key the player has to
## press, and is never announced.
##
## It is read from the event log and nothing else. That is what the external/derived
## split was paid for: `submit()` is what the player did, `derive()` is a system's
## answer, both are logged, and a journal that reconstructs "why" from them is the
## proof that the log really is the authoritative record of a run.

const GRAIN_IS_NEWS: float = 60.0


## One chronological list. Every row is {tick, line, because} — `because` is "" when
## the log does not support a claim, and an empty because is always better than a
## guessed one.
static func entries(events: EventLog, facts: FactBase = null) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	# What the last cause of each kind was, so an effect can name it. Carried
	# forward as the log is walked rather than searched backwards, because the log
	# is in order and searching invites picking the wrong one.
	var last_deed: Dictionary = {}
	var fraud_told: String = ""
	var army_has_fallen: bool = false
	var grain_reported: Dictionary = {}

	for event: SimEvent in events.all():
		match event.type:
			&"deed_witnessed":
				var deed: StringName = StringName(event.data.get("about", ""))
				var where: String = Region.place_name(StringName(event.data.get("town", "")))
				var seen: int = (event.data.get("witnesses", []) as Array).size()
				last_deed[deed] = {"tick": _tick_of(event), "where": where}
				rows.append(_row(_tick_of(event), _deed_line(deed, where, seen),
					_deed_cost(deed)))
			&"theft_unseen":
				rows.append(_row(_tick_of(event),
					"You took something in %s. Nobody was looking."
						% Region.place_name(StringName(event.data.get("town", ""))), ""))
			&"rumour_arrived":
				var about: StringName = StringName(event.data.get("about", ""))
				var town: String = Region.place_name(StringName(event.data.get("town", "")))
				var origin: Dictionary = last_deed.get(about, {}) as Dictionary
				if origin.is_empty() or String(origin["where"]) == town:
					continue
				var how: String = " Carried up the King's Road." \
					if bool(event.data.get("carried", false)) else ""
				rows.append(_row(_tick_of(event),
					"%s has heard about it." % town,
					"%s after %s, in %s.%s"
						% [_elapsed(float(event.data.get("days", 0.0))),
							_deed_phrase(about), origin["where"], how]))
			&"fraud_exposed":
				fraud_told = "the Muster"
				rows.append(_row(_tick_of(event),
					"You laid the pay fraud in front of the men it was stolen from.",
					"It was the only telling you had."))
			&"army_fell":
				if army_has_fallen:
					continue
				army_has_fallen = true
				rows.append(_row(_tick_of(event), "Men are walking out of the camp.",
					"Since the pay fraud was said aloud at %s." % fraud_told
						if fraud_told != "" else ""))
			&"grain_moved":
				var to: float = float(event.data.get("to", 0.0))
				var at: StringName = StringName(event.data.get("town", ""))
				if to < GRAIN_IS_NEWS or grain_reported.has(at):
					continue
				grain_reported[at] = true
				rows.append(_row(_tick_of(event),
					"Bread in %s costs what nobody there can pay." % Region.place_name(at),
					"The camp emptied, and the men who were fed are buying."
						if army_has_fallen else ""))
			&"escort_changed":
				rows.append(_row(_tick_of(event), "The king keeps %d at the gate, where he kept %d."
					% [int(event.data.get("to", 0)), int(event.data.get("from", 0))],
					"There are fewer men to send." if army_has_fallen else ""))
	return rows


## What you know, and who you had it from. §15's other half: this is where the
## player's real progression is visible, because progression here is knowledge.
static func knowledge(facts: FactBase, cast: Cast) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if facts == null:
		return rows
	for fact: StringName in facts.facts():
		# Not everything in the fact base is knowledge. "met:maddox" is bookkeeping.
		var described: String = String(cast.fact_descriptions.get(fact, "")) if cast != null else ""
		if described == "":
			continue
		var told_by := PackedStringArray()
		for source: StringName in facts.sources_of(fact):
			var npc: Npc = cast.get_npc(source) if cast != null else null
			told_by.append(npc.display_name if npc != null else String(source))
		rows.append({
			"fact": String(fact),
			"line": described,
			"from": "from %s" % ", ".join(told_by) if told_by.size() > 0 else "",
			"safe": facts.is_redundant(fact),
		})
	return rows


## Events are stamped with the step, because two key presses inside the same
## in-game minute must replay in order. A journal is read in in-game time, so it
## converts — the clock the player reads is not the clock the sim keeps.
static func _tick_of(event: SimEvent) -> int:
	return event.step / Sim.STEPS_PER_WORLD_TICK


static func _row(tick: int, line: String, because: String) -> Dictionary:
	return {"tick": tick, "line": line, "because": because}


static func _deed_line(deed: StringName, where: String, seen: int) -> String:
	var watched: String = "%d %s saw you" % [seen, "person" if seen == 1 else "people"]
	if deed == DeedRules.DEED_THEFT:
		return "You took something from a stall in %s. %s." % [where, watched]
	if deed == DeedRules.DEED_RESTITUTION:
		return "You put it back, in %s. %s." % [where, watched]
	if deed == DeedRules.DEED_WARNING:
		return "You told %s what was coming. %s." % [where, watched]
	return "Something happened in %s." % where


## What an act closed, for the acts that close something.
##
## The journal is the only place allowed to say this. The camp shows you a shut pay
## tent and never explains it; you come here to find out why, which is the whole of
## push the ambient, pull the attribution.
static func _deed_cost(deed: StringName) -> String:
	return "It was the only telling you had." if deed == DeedRules.DEED_WARNING else ""


static func _deed_phrase(deed: StringName) -> String:
	if deed == DeedRules.DEED_THEFT:
		return "you took something"
	if deed == DeedRules.DEED_WARNING:
		return "you gave the warning"
	return "it happened"


static func _elapsed(days: float) -> String:
	if days < 1.0:
		return "Hours"
	var whole: int = int(round(days))
	return "A day" if whole <= 1 else "%d days" % whole
